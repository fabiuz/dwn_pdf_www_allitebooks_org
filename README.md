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

Procedimentos pra baixar os livros:

**Obtenha a url do arquivo pdf/pub ou outro formato de todos os livros do site, usando o comando:**

    `get_books_of_www_allitebooks_org_2 -dfileurl`

O comando acima deve ser executado somente uma vez.

** Em seguida, baixe quantos livros desejar, usando o comando: **

`get_books_of_www_allitebooks_org_2 -qtbooks=<qt>`

No comando acima substitua `<qt>`, pela quantidade desejada.

Baixe nim e compile o arquivo:

`nim c --d:release get_books_of_www_allitebooks_org_2`

Futuramente, eu irei implementar uma opção pra baixar somente livros escolhidos pelo usuário. Por exemplo, pelo título do livro, pela categoria ou pelo nome do autor.

**Obs.:** Alguns links podem dar erro 404/400, em novas versões, estarei corrigindo isto.
Pois, identifiquei que alguns links são válidos.


