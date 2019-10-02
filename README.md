# Baixador de arquivos pdf pra o site: http://www.allitebooks.org
` Autor: Fábio Moura de Oliveira`       
` Data:  30-set-2019`

Pesquisando por arquivos pdf na net, acabei achando o site: http://www.allitebooks.org, comecei baixar alguns arquivos.
Mas resolvi baixar todos os arquivos, o problema é que há 835 páginas e cada página, há vários links de livros. Em cada link, acessado, há pelo menos 1 ou 2 links pra o endereço do arquivo pdf/pub a ser baixado.

Pra fazer isto manualmente, leva tempo, imagine, acessar cada uma das 835 páginas, em cada página, há vários links de livros, em cada link de livro, vc clica e vai pra a página detalhe do livro, nesta página detalhe do livro, há um ou mais links pra o arquivo pdf/pub a ser baixado.

Se eu for fazer isto manualmente, acessar 1 página por dia, todos os dias do mês, gastarei 2 anos.

Por este motivo, resolvi criar este programa pra baixar todos os arquivos pdf do site.

Tenho experiência em várias linguages de programação, recentemente, conheci a linguagem Nim.

Então, resolvi ler todo o manual da linguagem Nim, em 2 dias aprendi o básico de Nim.

Com a experiência que tenho em outras linguagens, não foi difícil aprender Nim.

Então, resolvi escrever este programa em Nim, pra baixar todos os arquivos pdf do site: http://www.allitebooks.org.

Obs.: Atualmente, o programa vai em cada página, localiza os livros, em seguida, de cada livro, baixa o arquivo pdf/pub e outros que tiver.
Estive implementando uma técnica pra baixar somente livros que ainda não foram baixados, mas tive algum problema
no banco de dados sqlite, estou verificando, então, por este motivo, o download pode durar horas, pois ele percorre todas as páginas e vai baixando automaticamente.

Pra baixar, vc deve executar o comando desta forma:

`get_books_of_www_allitebooks_org -durl`

## O que o programa faz:

Baixa todos os pdfs de cada página visitada.
Se o pdf não existir nada acontece, entretanto, é relatado em um arquivo qual link não funcionou.
Os pdfs são baixados e são criados pastas categorizando qual conteúdo é, tais informações são obtidos do próprio site.
Você pode interromper o download, entretanto, na próxima vez, vc deve começar tudo novamente.


## Pra fazer:
* Baixar somente pdfs que ainda não foram baixados.
* Verificar se há novos pdfs em relação ao anteriores.


