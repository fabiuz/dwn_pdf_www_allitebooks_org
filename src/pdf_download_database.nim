#[
    Iremos utilizar um banco de dados sqlite pra armazenar os dados dos livros.

    Iremos armazenar pra cada livro:
        A url da página onde o livro foi localizado.
        A url de cada arquivo do livro.

        Outros detalhes técnicos do livro, que estão disponíveis no site:
        autor, data, isbn-10, entre outros.

]#


#import times
#import db_sqlite
import db_postgres
import strutils

const DB_ARQUIVO* = "pdf_www_allitebooks_org.db"

type
    Livro* = object

        # Um ou mais autores do livro.
        autor*: string

        # Código Isbn do livro.
        isbn_10*: string

        # Data em que o livro foi criado.
        ano_data*: string

        # Idioma do qual o livro foi escrito.
        idioma*: string

        # Quantidade de páginas do livro.
        paginas*: string

        # A categoria do livro, está informação encontra-se
        # disponível também na página detalhe do livro.
        categoria*: string

        # Tamanho do arquivo.
        arquivo_tamanho*: string

        # Indica em quais formatos o livro se encontra.
        arquivo_formato*: string

        # nome do arquivo pdf/pub ou outro do livro.
        arquivo_nome*: string

        # A url da página no site, onde a url do livro foi localizada.
        paginaUrl*: string

        # A url da página detalhe do livro.
        livro_url*: string

        # A url do arquivo pdf/pub ou outro do livro.
        pdf_url*: string

        # A url codificada pra evitar caracteres especiais.
        pdf_url_encode*: string
        
        # diretório onde o arquivo foi salvo.
        diretorio*: string

        # indica se a url daquele livro já foi baixada, anteriormente.
        ja_baixado*: int

# type
#     User* = object
#         username*: string

#         # Defines a sequence named following in the User type,
#         # which will hold a list of usernames that the user has
#         # followed.
#         following*: seq[string]

#     # Defines a new Message value type.
#     Message* = object
#         # Defines a string field named username in the 
#         # Message type. This field will specify the unique
#         # name of the user who posted the message.
#         username*: string

#         # Defines a floating-point time field in the Message type.
#         # This field will store the time and date whe
#         # the message was posted.
#         time*: Time

#         # Defines a string field named msg in the Message type.
#         # This field will store the message that was posted.
#         msg*: string

type
    Database* = ref object
        db: DbConn

proc newDatabase*(filename = DB_ARQUIVO): Database = 
    new result
    result.db = open("", "ltk", "", "host=127.0.0.1 port=5432 dbname=allitebooks")

# proc inserirPaginaURL*(database: Database, pagina_url: string): void =
#     # Só inseri se não existir.
#     let row = database.db.getRow(
#         sql"Select pagina_url from allitebooks_pagina where pagina_url = ?;", pagina_url)
#     if row[0].len != 0:
#         return
    
#     database.db.exec(sql"Insert into allitebooks_pagina (pagina_url) values (?);", pagina_url)

# proc inserirPaginaURL*(database: Database, pagina_urls: seq[string]) =
#     for pagina_url in pagina_urls:
#         inserirPaginaURL(database, pagina_url)

# proc inserirLivroURL*(database: Database, pagina_url, livro_url: string): void =
#     # Só inseri se não existir.
#     let row = database.db.getRow(
#         sql"Select * from allitebooks_livro where pagina_url = ? and livro_url = ?;", pagina_url, livro_url)
#     if row[0].len != 0:
#         return

#     database.db.exec(sql"Insert into allitebooks_livro (pagina_url, livro_url) values (?, ?);", pagina_url, livro_url)

proc livroExiste*(database: Database, livro: Livro): bool =
    try:
        let row = database.db.getRow(
            sql"""
                Select livro_url, pdf_url from allitebooks_livro
                where livro_url = ? and pdf_url = ?
            """, livro.livro_url, livro.pdf_url)
        return row[0].len != 0

    except Exception:
        return false   


proc inserirLivro*(database: Database, livro: Livro): bool =
    try:
        if database.livroExiste(livro):
            return false

        database.db.exec(sql"""
            INSERT INTO allitebooks_livro
            (
                autor,
                isbn_10,
                ano_data,
                idioma,            
                paginas,
                
                categoria,
    
                arquivo_tamanho,
                arquivo_formato,
                arquivo_nome,
                
                pagina_url,
                livro_url,
                pdf_url,
    
                diretorio,
                
                ja_baixado            
            )VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);""",
            livro.autor,
            livro.isbn_10,
            livro.ano_data,
            livro.idioma,
            livro.paginas,

            livro.categoria,

            livro.arquivo_tamanho,
            livro.arquivo_formato,
            livro.arquivo_nome,

            livro.pagina_url,
            livro.livro_url,
            livro.pdf_url,

            livro.diretorio,

            livro.ja_baixado
        )
    except Exception:
        echo "Erro: " & getCurrentException().msg
        return false

    return true

proc inserirLivro*(database: Database, livros:seq[Livro]): bool =
    for livro in livros:
        if inserirLivro(database, livro) == false:
            return false

    return true

proc atualizarLivroJaBaixado*(database: Database, livro: Livro): int64 =
    ## Atualiza no banco de dados o livro indicando que já foi baixado.
    ## Retorna um valor diferente de 0 se a atualização ocorreu com sucesso.
    try:
        let rows = database.db.execAffectedRows(sql"""
            Update allitebooks_livro set ja_baixado = 1
            where livro_url = ? and pdf_url = ?
            """, livro.livro_url, livro.pdf_url)        
        return rows
    except Exception:
        return 0   

proc atualizarStatusHttp*(database: Database, livro: Livro, statusHttp: string): int64 =
    ## Atualiza o campo 'statusHttp' do banco de dados, quando houver algum erro.
    try:
        let rows = database.db.execAffectedRows(sql"""
            Update allitebooks_livro set status_http = ?
            where livro_url = ? and pdf_url = ?
            """, statusHttp, livro.livro_url, livro.pdf_url)  
        echo "qt: " & $rows      
        return rows
    except Exception:
        return 0   


proc obterQuantidadeLivrosNaoBaixados*(database: Database): int =
    ## Retorna a quantidade de livros ainda não baixados do site.
    ## e que não tenha nenhum erro na última vez que foram executados.
    try:
        let rows = database.db.getRow(sql"""
            Select count(*) as qt from allitebooks_livro
            where ja_baixado = 0
            and status_http is null
            """)
        return rows[0].parseInt      
    except Exception:
        echo getCurrentException().msg
        return 0

proc obterLivrosNaoBaixados*(database: Database, livros: var seq[Livro]): bool =
    ## Armazena todos os livros que ainda não foram realizados download do mesmo.
    try:
        livros.setLen(0)

        let rows = database.db.getAllRows(
            sql"""
                Select 
                    autor,
                    isbn_10,
                    ano_data,
                    idioma,            
                    paginas,
                    
                    categoria,
        
                    arquivo_tamanho,
                    arquivo_formato,
                    arquivo_nome,
                    
                    pagina_url,
                    livro_url,
                    pdf_url,
        
                    diretorio,
                    
                    ja_baixado  
                from allitebooks_livro
                where ja_baixado = 0
                and status_http is null
            """)

        for row in rows:
            var livro_detalhe: Livro
            livro_detalhe.autor = row[0]
            livro_detalhe.isbn_10 = row[1]
            livro_detalhe.ano_data = row[2]
            livro_detalhe.idioma = row[3]
            livro_detalhe.paginas = row[4]
            
            livro_detalhe.categoria = row[5]

            livro_detalhe.arquivo_tamanho = row[6]
            livro_detalhe.arquivo_formato = row[7]
            livro_detalhe.arquivo_nome = row[8]

            livro_detalhe.pagina_url = row[9]
            livro_detalhe.livro_url = row[10]
            livro_detalhe.pdf_url = row[11]

            livro_detalhe.diretorio = row[12]

            livro_detalhe.ja_baixado = row[13].parseInt

            livros.add(livro_detalhe)
        
    except Exception:
        echo "Erro: " & getCurrentException().msg
        return false

    return true

proc obterTodosLivros*(database:Database, livros: var seq[Livro]): bool =
    try:
        livros.setLen(0)

        let rows = database.db.getAllRows(
            sql"""
                Select 
                    autor,
                    isbn_10,
                    ano_data,
                    idioma,            
                    paginas,
                    
                    categoria,
        
                    arquivo_tamanho,
                    arquivo_formato,
                    arquivo_nome,
                    
                    pagina_url,
                    livro_url,
                    pdf_url,
        
                    diretorio,
                    
                    ja_baixado  
                from allitebooks_livro
                order by pagina_url asc
            """)

        for row in rows:
            var livro_detalhe: Livro
            livro_detalhe.autor = row[0]
            livro_detalhe.isbn_10 = row[1]
            livro_detalhe.ano_data = row[2]
            livro_detalhe.idioma = row[3]
            livro_detalhe.paginas = row[4]
            
            livro_detalhe.categoria = row[5]

            livro_detalhe.arquivo_tamanho = row[6]
            livro_detalhe.arquivo_formato = row[7]
            livro_detalhe.arquivo_nome = row[8]

            livro_detalhe.pagina_url = row[9]
            livro_detalhe.livro_url = row[10]
            livro_detalhe.pdf_url = row[11]

            livro_detalhe.diretorio = row[12]

            livro_detalhe.ja_baixado = row[13].parseInt

            livros.add(livro_detalhe)
        
    except Exception:
        echo "Erro: " & getCurrentException().msg
        return false

    return true



# proc post*(database: Database, message: Message) =
#     if message.msg.len > 140:
#         raise newException(ValueError, "Message has to be less than 140 characters.")

#     database.db.exec(sql"Insert into Message values(?, ?, ?);",
#         message.username, $message.time.toSeconds().int, message.msg)

# proc follow*(database: Database, follower: User, user: User) =
#     database.db.exec(sql"Insert into Following values (?, ?);",
#         follower.username, user.username)

# proc create*(database: Database, user: User) = 
#     database.db.exec(sql"Insert into User Values (?);", user.username)

# proc findUser*(database: Database, username: string, user: var User): bool =
#     let row = database.db.getRow(
#         sql"Select username from User where username = ?;", username)
#     if row[0].len == 0: 
#         return false
#     else:
#         user.username = row[0]

#     let following = database.db.getAllRows(
#         sql"Select followed_user from following where follower = ?;", username)
#     user.following = @[]

#     for row in following:
#         if row[0].len != 0:
#             user.following.add(row[0])
#     return true

# proc findMessages*(database: Database, usernames: seq[string],
#     limit = 10): seq[Message] =
#     result = @[]
#     if usernames.len == 0: return

#     var whereClause = " where "
#     for i in 0 ..< usernames.len:
#         whereClause.add("username = ? ")
#         if i != pred(usernames.len):
#             whereClause.add("or ")
    
#     let messages = database.db.getAllRows(
#         sql("Select username, time, msg from Message" & 
#             whereClause & "Order by time desc limit " & $limit), 
#             usernames)
    
#     for row in messages:
#         result.add(Message(username:row[0], time: fromSeconds(row[1].parseInt), 
#             msg: row[2]))

proc close*(database: Database) =
    database.db.close()

proc setup*(database: Database) =
    #[
        Um livro pode ter 1 ou mais arquivos.
    ]#
    discard database.db.tryExec(sql"""
        Create table if not exists allitebooks_livro(
            
            autor text not null,
            isbn_10 text not null,
            ano_data text not null,
            idioma text not null,            
            paginas text not null,
            
            categoria text not null,

            arquivo_tamanho text not null,
            arquivo_formato text not null,
            arquivo_nome text not null,
            
            pagina_url text not null,
            livro_url text not null,
            pdf_url text not null,

            diretorio text not null,
            
            ja_baixado integer not null,
            
            primary key (pagina_url, livro_url, pdf_url)
            
        );
    """)




