#[
    Baixador de arquivos pdf/pub e outros do site: http://www.allitebooks.org.
    Autor: Fábio Moura de Oliveira, 30-set-2019.
    Descrição:
        Baixa cada arquivo do site e ainda categoriza o arquivo pdf, semelhante ao site.

    Motivações:
        Dia 27-set-2019, estava estudando a linguagem Nim, pela primeira vez,
        resolvi, procurar na internet por arquivos pdf, principalmente, por
        conteúdos relacionado a Nim, acabei encontrando o site: 
        http://www.allitebooks.org. 

        Neste site, há centenas de livros em pdf/pub, deve ter outros formatos 
        também, no momento que escrevo, há 835 páginas, cada página, tem 10
        links de livros.

        Então, há 8350 livros, se eu for baixar 10 livros por dia, todos os dias,
        gastarei 2 anos pra fazer isto.
]#

import httpClient
import htmlparser
import xmltree
import xmlparser
import strtabs
import strutils
import os       
import streams
import pdf_download_database
import times

const SITE_URL = "http://www.allitebooks.org/"

proc allitebooks_obter_paginas(url_paginas: var seq[string]): bool =
    #[
        A página principal do site é: http://www.allitebooks.org
        Nesta página, vc pode acessar por categoria ou acessar todos os livros.
        
        Na página principal, há links, pra as páginas seguintes, e pra a última
        página.

        O que faremos nesta procedure é a partir da página principal, localizar
        todos os links de páginas que está na página principal, depois, iremos
        visitar cada página e também localizar todos os links de páginas e assim por
        diante.

        Iremos armazenar cada página, em uma variável sequência e vamos percorrendo
        cada posição desta sequência.

        Como em um página, pode haver link pra páginas antecessoras e sucessoras, devemos
        armazenar na variável sequência somente links que ainda não foram inseridos.

        O link das páginas fica dentro da tag: "<div class="pagination clearfix">        
        Dentro desta tag, há várias tag "a", que tem justamente os links pra as próximas
        páginas.
    ]#

    url_paginas.setLen(0)
    url_paginas.add(SITE_URL)

    var http_client = newHttpClient()

    # Não é possível utilizar
    var indice = 0
    while indice < url_paginas.len:
        var url_pagina = url_paginas[indice]
        echo "Obtendo links das próximas páginas de: ", url_pagina

        # Vamos colocar um 'try:except' e também
        # um número de tentativas pra tentar baixar o arquivo,
        # caso ocorra algum problema na conexao.
        var html_conteudo = ""
        var tentativas = 0

        while true:
            try:
                html_conteudo = http_client.getContent(url_pagina)    
                break            
            except Exception:
                inc tentativas
                echo "Erro ao conectar em " & url_pagina
                echo "Tentando novamente, tentativa " & $tentativas & " de 10"

                if tentativas == 10:
                    quit ("Erro ao baixar: " & getCurrentException().msg)
        
        var html_node = parseHtml(html_conteudo)

        #[
        O contéudo dos link das próximas páginas, fica dentro da tag:
        <div class="pagination clearfix">
        ]#

        for tag_div in html_node.findAll("div"):
            if tag_div.attrs == nil:
                continue
            
            if tag_div.attrs.hasKey("class") == false:
                continue

            if tag_div.attrs["class"] != "pagination clearfix":
                continue

            #[
                Se chegarmos aqui, estamos dentro da tag '<div class="pagination clearfix">
                Dentro desta tag, há varias tags "a", que tem link pra as próximas páginas.
            ]#
            for url_outra_pagina in tag_div.findAll("a"):
                if url_outra_pagina.attrs == nil:
                    continue
                
                if url_outra_pagina.attrs.hasKey("href") == false:
                    continue

                var url_outra_pagina_link = url_outra_pagina.attrs["href"]
                if url_outra_pagina_link.strip == "":
                    continue

                if url_paginas.contains(url_outra_pagina_link) == false:
                    url_paginas.add(url_outra_pagina_link)

        indice.inc

proc allitebooks_obter_link_das_paginas_de_uma_pagina(pagina_urls: var seq[string], url_pagina:string): bool {.inline.}=
    #[
        No site "http://www.allitebooks.org", cada página, tem links que apontam pra outras páginas.
        O que está procedure faz é captura todos os links que tem em uma página.

        O link das páginas fica dentro da tag: "<div class="pagination clearfix">        
        Dentro desta tag, há várias tag "a", que tem justamente os links pra as próximas
        páginas.
    ]#

    # Vamos realizar algumas validações.
    if url_pagina.strip == "":
        return false

    # Garante que a sequência está vazia.
    pagina_urls.setLen(0)
    
    var html_conteudo = ""
    var tentativas = 0
    while true:
        try:
            var http_client = newHttpClient()
            html_conteudo = http_client.getContent(url_pagina)
            break

        except Exception:
            # Caso ocorra erros, iremos tentar 10 vezes, se após der erro,
            # retorna como false, indicando que não conseguimos obter o conteudo.
            inc tentativas
            if tentativas == 10:
                echo "Erro: " & getCurrentException().msg
                return false

    # transforma o conteúdo em um xml_node pra ser analisado o html.
    var html_node = parseHtml(html_conteudo)

    #[
        O contéudo dos link das próximas páginas, fica dentro da tag:
        <div class="pagination clearfix">
        O loop for visita todas as tags div que tem o atributo "class"
        igual a "pagination clearfix" e obtém todos os links
        dentro da tag.
    ]#

    for tag_div in html_node.findAll("div"):
        # Se a tag não tem atributo, a propriedade 'attrs' será nil.
        if tag_div.attrs == nil:
            continue
        
        # Se estamos buscando div que tem o atributo class definido,
        # se não tive devemos visitar a próxima tag div.
        if tag_div.attrs.hasKey("class") == false:
            continue

        # Só estamos buscando div com o atributo class igual a "pagination clearfix",
        # se não tiver, devemos ir pra a próxima tag div.
        if tag_div.attrs["class"] != "pagination clearfix":
            continue

        #[
            Se chegarmos aqui, estamos dentro da tag '<div class="pagination clearfix">
            Dentro desta tag, há varias tags "a", que tem link pra as próximas páginas.
        ]#
        for url_outra_pagina in tag_div.findAll("a"):
            if url_outra_pagina.attrs == nil:
                continue
            
            if url_outra_pagina.attrs.hasKey("href") == false:
                continue

            var url_outra_pagina_link = url_outra_pagina.attrs["href"]
            if url_outra_pagina_link.strip == "":
                continue

            if pagina_urls.contains(url_outra_pagina_link) == false:
                pagina_urls.add(url_outra_pagina_link)

    return true



proc allitebooks_obter_link_dos_livros_de_uma_pagina(livro_url_link: var seq[string], url_pagina:string): bool =
    #[
        Esta procedure serve pra obter todos os links de livros de uma única página.
        Tais links não são links pra arquivos pdf/pub e sim link pra detalhes de um livro.
        E lá no detalhe do livros, que há link dos arquivos pdf/pub.

        Na página, os links dos livros estão dentro de uma tag article,
        que tem o atributo "id" começando em "post-".

        Então, esta procedure visitará todos as tags article e se
        tal tag, tiver o atributo "id" começando em "post-", iremos
        capturar todos os links que estão dentro desta tag.

    ]#
    livro_url_link.setLen(0)

    var http_client = newHttpClient()
    var html_conteudo = ""
    try:
        html_conteudo = http_client.getContent(url_pagina)
    except Exception:
        return false

    var html_node = parseHtml(html_conteudo)

    #[
        No loop for abaixo, iremos visitar todas as tags article,
        e a tag article tiver o atributo id começando com "post-",
        iremos capturar todos os links, pois são links de livros.
        Observação: Não capturamos links duplicados.
    ]#
    for tag_article in html_node.findAll("article"):
        if tag_article.attrs == nil:
            continue

        if tag_article.attrs.hasKey("id") == false:
            continue

        var article_id = tag_article.attrs["id"]
        if article_id == "":
          continue
    
        if article_id.startsWith("post-"):
          # Obtém todos os links que estão dentro de "post-".
          #[
              Dentro da tag <article> que tem o atributo "id" começando com "post-",
              temos várias tags "a" que estão dentro de três divs que são secundárias
              da tag article.
              Um tag a, tem o link pra a página detalhe do livro, a outra tag
              a, tem o link pra a página do autor e de lá há os links dos livros.

              Tecnicamente, a página do autor, não é a página de link de um livro,
              por este motivo, no momento, iremos pegar somente a página detalhe do
              livro.

              Então, toda a url que tem '/author', não iremos inserir.

          ]#
          for tag_a in tag_article.findAll("a"):
            # Obtém o link que está no atributo "href" da tag "a".
            var href = tag_a.attrs["href"]
            if href == "":
              continue

            #[
                Dentro da tag "<article id="post-", há várias tags a,
                um das tags, aponta pra a página detalhe do livro e a
                outra tag, aponta pra a página do autor, estamos
                interessando somente na url que aponta pra a página detalhe do
                livro.
            ]#
            if href.contains("/author/"):
                continue
    
            # Só adiciona se o link não existe ainda na sequência.
            if livro_url_link.contains(href) == false:
              livro_url_link.add(href)     

    http_client.close()
    
    return true

proc allitebooks_obter_link_pdf_de_um_livro(link_url_livro: string, arquivo_livro: var seq[Livro]): bool {.inline}=
    #[
        Obtém todos os links pdf/pub e outros formatos de arquivos de um único livro.
        Além disto retorna informações mais detalhadas do livro.
    ]#
    arquivo_livro.setLen(0)

    var http_client = newHttpClient()

    # Obtém o contéudo da página atual.
    var html_site_conteudo = http_client.getContent(link_url_livro)


    # Em seguida, transformamos em um xml node pra poder analisar o html.
    var html_node = parseHtml(html_site_conteudo)

    #[
        Pode haver 1 ou mais arquivos pra um mesmo livro.
        Cada arquivo está em um formato, por exemplo, pdf, pub.
        Então, em todos eles, eles terão os mesmos dados, alterando
        somente algumas informações relacionado ao arquivo em si,
        então, a variável abaixo, terão os dados em comum a todos
        os arquivos.
    ]#
    var livro_detalhe: Livro    

    # Vamos obter primeiro o detalhe do livro, fica na tag:
    # <div class="book-detail">
    # Vamos percorrer todas as divs até encontrar uma que tenha
    # class igual a "book-detail".  
    for tag_div in html_node.findAll("div"):
        # Pode acontecer de uma tag, não tem um atributo, sendo neste caso nil.
        if tag_div.attrs == nil:
            continue

        # Só iremos procurar por tags que tem o atributo 'class', se não tem
        # atributo, devemos visitar a próxima tag.
        if tag_div.attrs.contains("class") == false:
            continue
        
        # Só iremos procurar por tags que tem o atributo 'book-detail',
        # se a tag atual sendo visitada não tem no atributo "class" o valor
        # book-details, devemos visitar a próxima tag.
        if tag_div.attrs["class"] != "book-detail":
            continue

        #[
            Tecnicamente, há duas maneiras de obter os dados de um livro
            dentro da tag 'book-detail', percorrendo cada tag ou 
            retornando o innerHtml da tag book-detail.
            Achei mais prático neste caso, retorna 'innerHtml' pois
            ele já retorna um string com várias linhas onde cada
            linha representa um detalhe do livro e está interseparado
            pelo caractere ':'.
        ]#
        var livro_texto = tag_div.innerText.unindent.strip()
        
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
                of "year": livro_detalhe.ano_data = valor_atual
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

        for tag_span in html_node.findAll("span"):
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
                livro_detalhe.pdf_url = tag_a.attrs["href"]

                # Nome do arquivo está no final da url.
                livro_detalhe.arquivo_nome = livro_detalhe.pdf_url.split("/")[^1]

                # Vamos retirar o nome do arquivo do final.
                livro_detalhe.diretorio = livro_detalhe.pdf_url.replace("http://", "http.").replace("/", "_")
                livro_detalhe.diretorio = livro_detalhe.diretorio.replace("_" & livro_detalhe.arquivo_nome, "")
                livro_detalhe.diretorio = livro_detalhe.diretorio.replace("_", "/")

                echo "diretorio: " & livro_detalhe.diretorio
                echo "categoria: " & livro_detalhe.categoria

     
                # O diretorio terá o nome da categoria, antes:
                livro_detalhe.diretorio = livro_detalhe.categoria & "/" & livro_detalhe.diretorio
                echo livro_detalhe.diretorio

                arquivo_livro.add(livro_detalhe)

    return true

proc allitebooks_baixar_livro(livro_detalhe: Livro): bool =
    #[
        Baixa um livro, criando um diretório baseado na categoria do livro.
        Haverá vários subdiretórios, praticamente, o diretório é semelhante
        ao diretório do site.
    ]#

    var pdf_conteudo = ""
    var tentativas = 0
    var client_http: HttpClient

    while true:
        try:
            echo "entrou no client_http."
            client_http = newHttpClient()
            pdf_conteudo = client_http.getContent(livro_detalhe.pdf_url)   
            echo "chegou aqui...."             
            break;
        except Exception:
            echo "Exceção..."
            tentativas.inc
            if tentativas == 10:
                return false

    # Iremos criar o diretório e criar o arquivo, somente se o donwload ocorreu
    # normalmente.    
    if dirExists(livro_detalhe.diretorio) == false:
        createDir(livro_detalhe.diretorio)

    #echo "livro_detalhe.diretorio=" & livro_detalhe.diretorio

    # Cria o arquivo dentro do diretório predefinido pra este arquivo.
    var pdf_arquivo = newFileStream(livro_detalhe.diretorio & "/" & livro_detalhe.arquivo_nome, fmWrite)

    #echo livro_detalhe.diretorio & "/" & livro_detalhe.arquivo_nome

    pdf_arquivo.write(pdf_conteudo)
    
    pdf_arquivo.close()

    client_http.close()

    return true

proc exibir_ajuda():void =
    echo """
        get_books_of_www_allitebooks_org, version: 1.0.0
        Get all books of the site http://www.allitebooks.org.
        Author: Fábio Moura de Oliveira, 2019-oct-01

        Use:
            get_books_of_www_allitebooks <options>

        Where <options> is:
            -durl   Armazena a url de cada livro de todas as páginas,
                    pra o pdf/pub ser baixado posteriormente.

            -dfile  Baixa todos os pdf de cada url que foi salva
                    anteriormente usando a opção -durl.
                    O programa só irá baixar pdf que ainda não foram baixados.            

    """
    

proc salvar_arquivo_csv(arquivo: Stream, livro: Livro): void =
    var texto = ""
    texto.add(livro.autor)
    texto.add(",")
    texto.add(livro.isbn_10)
    texto.add(",")
    texto.add(livro.ano_data)
    texto.add(",")
    texto.add(livro.paginas)
    texto.add(",")
    texto.add(livro.idioma)
    texto.add(",")
    texto.add(livro.arquivo_tamanho)
    texto.add(",")
    texto.add(livro.arquivo_formato)
    texto.add(",")
    texto.add(livro.categoria)
    texto.add(",")
    texto.add(livro.pdf_url)
    texto.add(",")
    texto.add(livro.livro_url)
    texto.add(",")
    texto.add(livro.pagina_url)
    texto.add(",")
    texto.add(livro.diretorio)
    texto.add(",")
    texto.add(livro.arquivo_nome)
    texto.add(",")
    texto.add(livro.ja_baixado)

    arquivo.writeline(texto)

    discard

proc salvar_urls_dos_arquivos_do_livro():void =
    var arquivo_baixado = newFileStream("link_pdf_baixado.csv", fmWrite)
    var arquivo_nao_baixado = newFileStream("link_pdf_nao_baixado.csv", fmWrite)
    
    #var pdf_db = newDatabase()
    #pdf_db.setup()


    var site_paginas = @[SITE_URL]
    var indice = 0

    var qt_livros = 0
    var qt_arquivos = 0

    #[
        No loop abaixo, iremos em cada página, captura todos os links que apontam pra a pŕoxima
        página. Tais links capturados serão adicionados na variável 'site_paginas'.
        Em seguida, na próxima iteração do loop, iremos captura todos os links que adicionar
        na variável 'site_paginas', iremos adicionar somente urls que ainda não foram
        adicionadas, iremos repetir com cada url adicionada.
    ]#
    while indice < site_paginas.len:
        echo "Obtendo páginas de: " & site_paginas[indice]

        #pdf_db.inserirPaginaURL(site_paginas[indice])

        var site_outras_paginas: seq[string]
        discard allitebooks_obter_link_das_paginas_de_uma_pagina(site_outras_paginas, site_paginas[indice])

        for pagina in site_outras_paginas:
            if site_paginas.contains(pagina) == false:
                site_paginas.add(pagina)

        # Obtém o link dos livros de cada página.
        var livro_urls: seq[string]        
        discard allitebooks_obter_link_dos_livros_de_uma_pagina(livro_urls, site_paginas[indice])
        
        echo ""
        echo "\t###### LINK DE LIVROS ENCONTRADOS #########"
        for livro_url in livro_urls:
            
            inc qt_livros
            echo "\t[" & $qt_livros & "]:" & livro_url

            #inserirLivroURL(pdf_db, site_paginas[indice], livro_url)

            # Obter todos os links de arquivos pdf/pub e outros, da url do livro.
            var arquivo_livro:seq[Livro]
            arquivo_livro.setLen(0)
            if allitebooks_obter_link_pdf_de_um_livro(livro_url, arquivo_livro) == true:
                echo "\t\t" & $arquivo_livro.len & " encontrados."
                qt_arquivos += arquivo_livro.len    
            else:
                echo "\t\t" & $arquivo_livro.len & " encontrados."

            for arquivo in arquivo_livro:
                if allitebooks_baixar_livro(arquivo) == true:
                    salvar_arquivo_csv(arquivo_baixado, arquivo)
                else:
                    salvar_arquivo_csv(arquivo_nao_baixado, arquivo)

            # Salva no banco de dados.
            #if pdf_db.inserirLivro(arquivo_livro) == false:
            #    continue

        echo ""
        indice.inc

    arquivo_baixado.close
    arquivo_nao_baixado.close
    
    echo "############ Estatísticas ###########"
    echo "Livros:  " & $qt_livros & " encontrados."
    echo "Arquivos:" & $qt_arquivos & " encontrados."


#[
            autor*: string
        isbn_10*: string
        ano_data*: string
        paginas*: int32
        idioma*: string
        arquivo_tamanho*: string
        arquivo_formato*: string
        categoria*: string

        pdf_url*: string
        livro_url*: string
        pagina_url*: string

        diretorio*: string
        arquivo_nome*: string
        ja_baixado: int8
]#




if paramCount() == 0:
    exibir_ajuda()
    quit()      

if paramCount() == 1:
    if paramStr(1) == "-durl":
        salvar_urls_dos_arquivos_do_livro()



        
        

    
    







