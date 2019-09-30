#[
  Programa:   Baixador de arquivos do site: http://www.allitebooks.org.
  Autor:      Fábio Moura de Oliveira.
  Descrição: 
  Dia 27-set-2019, procurando por arquivos pdf, acabei encontrando o site:
    http://www.allitebooks.org, o site divide os livros por categoria,
    há no dia que estou escrevendo este código, 835 livros, cheguei a baixar
    alguns livros mais queria baixar todos e a única maneira de fazer isto,
    é criando um programa que acessa todos os links.
    Por este motivo, estou criando meu primeiro programa na linguagem 'nim'
    que faz isto.
]#
import httpClient
import htmlparser
import xmltree
import xmlparser
import strtabs
import strutils
import os # Este import será utilizado pra criar as pastas onde iremos armazenar os livros.
import streams

const SITE_URL = "http://www.allitebooks.org/"

echo "dwn_pdf_www_allitebooks_org, v.1.0.0"
echo "Baixador de pdf do site: " & SITE_URL
echo "Autor: Fábio"

var client_http = newHttpClient()
var html_site:string = client_http.getContent(SITE_URL)

#[
  Na página principal do site: http://www.allitebooks.org é exibido
  vários livros, inclusive, você pode selecionar os livros por categoria.
]#
let html_conteudo = parseHtml(html_site)

var url_pages:seq[string] = @[SITE_URL]

#[
  Na página principal, também, é demonstrado quantas páginas totais de livros há,
  e há link pra as demais páginas, os links tem este formato:
    http://www.allitebooks.org/pages/2
    http://www.allitebooks.org/pages/3

  Como nosso objetivo é obter todas as páginas pra obter todos os livros, precisamos
  saber quantas páginas há.
  Pra isto, esta informação fica dentro da tag "<div class="pagination clearfix">
  E dentro desta tag, há várias tags: "a", cada link aponta pra a próxima página,
  entretanto, um destes links aponta pra a última página.
  Pra isto, vamos obter estes links e em seguida, descobrir qual é esta última página.
]#

# Vamos percorrer cada url localizada.
var indice = 0
while indice < url_pages.len:
  var url_atual = url_pages[indice]
  echo("Lendo conteúdo do site: ", url_atual)

  # Vamos obter o contéudo da url atual.
  var html_site_conteudo = client_http.getContent(url_atual)

  # E em seguida, transforma em um xml node, pra pode analisar o contéudo html.
  var html_xmlnode = parseHtml(html_site_conteudo)

  #[
    O contéudo dos link das próximas páginas, fica dentro da tag:
      <div class="pagination clearfix">
  ]#
  for tag_div in html_xmlnode.findAll("div"):
    if tag_div.attrs.hasKey("class") == false:
      continue
    
    if tag_div.attrs["class"] != "pagination clearfix":
      continue

    #[
      E dentro, há vários links, onde um dos links, é o link da
      última página.
    ]#
    for url_book_pages in tag_div.findAll("a"):
      var url_page:string = url_book_pages.attrs["href"]
      if url_page == "":
        continue

      # Só iremos adicionar, se a url ainda não foi adicionada.
      if url_pages.contains(url_page) == false:
        url_pages.add(url_page)

  inc(indice)

# Agora, vamos obter o link de cada livro, de cada página.
# pra isto, iremos armazenar em uma sequência.
var livro_url_link:seq[string] = @[]

# Ler o conteúdo de cada página.
for pagina_atual in url_pages:
  # Obtém o contéudo da página atual.
  var html_site_conteudo = client_http.getContent(pagina_atual)

  # Em seguida, transformamos em um xml node pra poder analisar o html.
  var html_xmlnode = parseHtml(html_site_conteudo)

  # Iremos procurar todas as tags "article" que tem o prefixo "post-", no
  # atributo "id".
  # Dentro desta tag, há o link de um único livro.
  echo "url dos livros, do link: ", pagina_atual, ":"
  for tag_article in html_xmlnode.findAll("article"):
    var article_id = tag_article.attrs["id"]
    if article_id == "":
      continue

    if article_id.startsWith("post-"):
      # Obtém todos os links que estão dentro de "post-".
      for tag_a in tag_article.findAll("a"):
        # Obtém o link que está no atributo "href" da tag "a".
        var href = tag_a.attrs["href"]
        if href == "":
          continue

        # Só adiciona se o link não existe ainda na sequência.
        if livro_url_link.contains(href) == false:
          livro_url_link.add(href)
          echo(href)

  echo("")

# Após sair, temos um sequência com vários links, pra a página
# detalhada do livro.
# Podemos limpar a sequência que armazena o link das páginas do site, não precisamos mais.
url_pages.setLen(0)

type
  livro = object
    autor: string
    isbn_10: string
    ano_data: string
    paginas: int32
    idioma: string
    arquivo_tamanho: string
    arquivo_formato: string
    categoria: string
    url_pdf: string
    diretorio: string
    arquivo_nome: string

var livros_download: seq[livro] = @[]

for livro_url in livro_url_link:
  # Obtém o contéudo da página atual.
  var html_site_conteudo = client_http.getContent(livro_url)

  # Em seguida, transformamos em um xml node pra poder analisar o html.
  var html_xmlnode = parseHtml(html_site_conteudo)

  # Obtém os detalhes do livro.
  var livro_detalhe: livro    

  # Vamos obter primeiro o detalhe do livro, fica na tag:
  # <div class="book-detail">
  # Vamos percorrer todas as divs até encontrar uma que tenha
  # class igual a "book-detail".  
  for tag_div in html_xmlnode.findAll("div"):
    if tag_div.attrs == nil:
      continue

    if tag_div.attrs.contains("class") == false:
      continue
    
    if tag_div.attrs["class"] != "book-detail":
      continue

    # Os dados do livro estão dentro de um tag "dl"
    # Aqui, achei mais prático pegar o texto, do que buscar o conteúdo
    # das tags, pois, já sai formato neste padrão => chave: valor, separado
    # por linhas.
    var livro_texto = tag_div.innerText.unindent.strip
    
    for campos in livro_texto.splitLines():
      var chave_valor = campos.split(":")
      if chave_valor.len != 2:
        continue

      var valor_atual = chave_valor[1].strip()
      
      case chave_valor[0].toLower()
      of "author":
        livro_detalhe.autor = valor_atual
      of "isbn-10":
        livro_detalhe.isbn_10 = valor_atual
      of "year":
        livro_detalhe.ano_data = valor_atual
      of "pages":
        livro_detalhe.paginas = cast[int32](valor_atual)
      of "language":
        livro_detalhe.idioma = valor_atual
      of "file size":
        livro_detalhe.arquivo_tamanho = valor_atual
      of "file_format":
        livro_detalhe.arquivo_formato = valor_atual
      of "category":
        livro_detalhe.categoria = valor_atual
      else:
        discard

  for tag_span in html_xmlnode.findAll("span"):
    if tag_span.attrs == nil:
      continue

    if tag_span.attrs.hasKey("class") == false:
      continue
    
    if tag_span.attrs["class"] != "download-links":
      continue

    for tag_a in tag_span.findAll("a"):
      if tag_a.attrs.hasKey("href") == false:
        continue

      # Vamos obter informações do arquivo.
      #var livro_atual:livro
      livro_detalhe.url_pdf = tag_a.attrs["href"]

      # Nome do arquivo está no final da url.
      livro_detalhe.arquivo_nome = livro_detalhe.url_pdf.split("/")[^1]

      # Vamos retirar o nome do arquivo do final.
      livro_detalhe.diretorio = livro_detalhe.url_pdf.replace("http://", "http_").replace("/", "_")
      livro_detalhe.diretorio = livro_detalhe.diretorio.replace("_" & livro_detalhe.arquivo_nome, "")
      livro_detalhe.diretorio = livro_detalhe.diretorio.replace("_", "/")

      # O diretorio terá o nome da categoria, antes:
      livro_detalhe.diretorio = livro_detalhe.categoria & "_" & livro_detalhe.diretorio

      livros_download.add(livro_detalhe)

# Vamos baixar alguns livros.
for livro_detalhe in livros_download:
  echo "Baixando livro: ", livro_detalhe.arquivo_nome

  if dirExists(livro_detalhe.diretorio) == false:
    createDir(livro_detalhe.diretorio)

  var pdf_arquivo = newFileStream(livro_detalhe.diretorio & "/" & livro_detalhe.arquivo_nome, fmWrite)

  var conteudo:string = client_http.getContent(livro_detalhe.url_pdf)

  pdf_arquivo.write(conteudo)

  pdf_arquivo.close()

if isMainModule:
  discard()
