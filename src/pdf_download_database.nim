#[
    Iremos utilizar um banco de dados sqlite pra armazenar os dados dos livros.

    Iremos armazenar:
        Os links das páginas que tem links de livros.
        Os links dos livros que tem links de arquivos pdf/pub e outros.
        Os links dos pdfs.

        Além dos links pdfs/pub, iremos armazenar pra cada livro,
        o autor, data entre outros.

        Além disto, iremos indicar se o arquivo pdf/pub e outros foram baixados
        pra a máquina.

]#


import times
import db_sqlite
import strutils

const DB_ARQUIVO* = "pdf_www_allitebooks_org.db"

type
    Livro* = object
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
        ja_baixado*: int8

type
    User* = object
        username*: string

        # Defines a sequence named following in the User type,
        # which will hold a list of usernames that the user has
        # followed.
        following*: seq[string]

    # Defines a new Message value type.
    Message* = object
        # Defines a string field named username in the 
        # Message type. This field will specify the unique
        # name of the user who posted the message.
        username*: string

        # Defines a floating-point time field in the Message type.
        # This field will store the time and date whe
        # the message was posted.
        time*: Time

        # Defines a string field named msg in the Message type.
        # This field will store the message that was posted.
        msg*: string

type
    Database* = ref object
        db: DbConn

proc newDatabase*(filename = DB_ARQUIVO): Database = 
    new result
    result.db = open(filename, "", "", "")

proc inserirPaginaURL*(database: Database, pagina_url: string): void =
    # Só inseri se não existir.
    let row = database.db.getRow(
        sql"Select pagina_url from allitebooks_pagina where pagina_url = ?;", pagina_url)
    if row[0].len != 0:
        return
    
    database.db.exec(sql"Insert into allitebooks_pagina (pagina_url) values (?);", pagina_url)

proc inserirPaginaURL*(database: Database, pagina_urls: seq[string]) =
    for pagina_url in pagina_urls:
        inserirPaginaURL(database, pagina_url)

proc inserirLivroURL*(database: Database, pagina_url, livro_url: string): void =
    # Só inseri se não existir.
    let row = database.db.getRow(
        sql"Select * from allitebooks_livro where pagina_url = ? and livro_url = ?;", pagina_url, livro_url)
    if row[0].len != 0:
        return

    database.db.exec(sql"Insert into allitebooks_livro (pagina_url, livro_url) values (?, ?);", pagina_url, livro_url)

proc livroExiste*(database: Database, livro: Livro): bool =
    try:
        let row = database.db.getRow(
            sql"""
                Select livro_url, pdf_url from allitebooks_livro_arquivo
                where livro_url = ? and url_pdf = ?
            """, livro.livro_url, livro.pdf_url)
        echo row
        return row[0].len != 0

    except Exception:
        return false      

proc inserirLivro*(database: Database, livro: Livro): bool =
    try:
        if database.livroExiste(livro):
            return false

        database.db.exec(sql"""
            INSERT INTO allitebooks_livro_arquivo
            (autor, isbn_10, ano_data, idioma, arquivo_tamanho, arquivo_formato, categoria, pdf_url, diretorio, arquivo_nome, ja_baixado, livro_url)
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);""",
            livro.autor,
            livro.isbn_10,
            livro.ano_data,
            livro.idioma,
            livro.arquivo_tamanho,
            livro.arquivo_formato,
            livro.categoria,
            livro.pdf_url,
            livro.diretorio,
            livro.arquivo_nome,
            livro.ja_baixado,
            livro.livro_url
        )
    except Exception:
        echo "Erro: " & getCurrentException().msg
        return false

    return true

proc obterLivrosNaoBaixados*(database: Database, livros: var seq[Livro]): bool =
    try:
        livros.setLen(0)

        let rows = database.db.getAllRows(
            sql"""
                Select 
                    autor, isbn_10, ano_data, idioma,
                    arquivo_tamanho, arquivo_formato, categoria, pdf_url,
                    diretorio, arquivo_nome, ja_baixado, livro_url
                from allitebooks_livro_arquivo
                where ja_baixado = 0
            """)

        for row in rows:
            var livro_detalhe: Livro
            livro_detalhe.autor = row[0]
            livro_detalhe.isbn_10 = row[1]
            livro_detalhe.ano_data = row[2]
            livro_detalhe.idioma = row[3]
            livro_detalhe.arquivo_tamanho = row[4]
            livro_detalhe.arquivo_formato = row[5]
            livro_detalhe.categoria = row[6]
            livro_detalhe.pdf_url = row[7]
            livro_detalhe.diretorio = row[8]
            livro_detalhe.arquivo_nome = row[9]
            livro_detalhe.ja_baixado = cast[int8](row[10])
            livro_detalhe.livro_url = row[11]

            livros.add(livro_detalhe)
        
    except Exception:
        echo "Erro: " & getCurrentException().msg
        return false

    return true
        

proc inserirLivro*(database: Database, livros:seq[Livro]): bool =
    for livro in livros:
        if inserirLivro(database, livro) == false:
            return false

    return true


proc post*(database: Database, message: Message) =
    if message.msg.len > 140:
        raise newException(ValueError, "Message has to be less than 140 characters.")

    database.db.exec(sql"Insert into Message values(?, ?, ?);",
        message.username, $message.time.toSeconds().int, message.msg)

proc follow*(database: Database, follower: User, user: User) =
    database.db.exec(sql"Insert into Following values (?, ?);",
        follower.username, user.username)

proc create*(database: Database, user: User) = 
    database.db.exec(sql"Insert into User Values (?);", user.username)

proc findUser*(database: Database, username: string, user: var User): bool =
    let row = database.db.getRow(
        sql"Select username from User where username = ?;", username)
    if row[0].len == 0: 
        return false
    else:
        user.username = row[0]

    let following = database.db.getAllRows(
        sql"Select followed_user from following where follower = ?;", username)
    user.following = @[]

    for row in following:
        if row[0].len != 0:
            user.following.add(row[0])
    return true

proc findMessages*(database: Database, usernames: seq[string],
    limit = 10): seq[Message] =
    result = @[]
    if usernames.len == 0: return

    var whereClause = " where "
    for i in 0 ..< usernames.len:
        whereClause.add("username = ? ")
        if i != pred(usernames.len):
            whereClause.add("or ")
    
    let messages = database.db.getAllRows(
        sql("Select username, time, msg from Message" & 
            whereClause & "Order by time desc limit " & $limit), 
            usernames)
    
    for row in messages:
        result.add(Message(username:row[0], time: fromSeconds(row[1].parseInt), 
            msg: row[2]))

proc close*(database: Database) =
    database.db.close()

proc setup*(database: Database) =
    #[
        Armazena a url de todas as páginas que contém link de livros.        
    ]#
    database.db.exec(sql"""
        Create table if not exists allitebooks_pagina(
            pagina_url text not null,
            primary key(pagina_url)
        );
    """)

    #[
        Cada página, pode ter 1 ou mais links de livros, por isto,
        iremos armazenar, os links de todos os livros da páginas.
        É o link do livro, não é o link do pdf do livro.
        Pra acessar quais são os pdf/pub do livro, vc precisa acessar
        o link do livro.
    ]#
    #[
        Uma página pode ter 1 ou mais links de um livro.
    ]#
    database.db.exec(sql"""
        Create table if not exists allitebooks_livro(
            livro_url text not null,
            pagina_url text not null,
            primary key (pagina_url, livro_url),
            foreign key (pagina_url) references allitebooks_pagina(pagina_url)
        );
    """)

    #[
        Um livro pode ter 1 ou mais arquivos.
    ]#
    database.db.exec(sql"""
        Create table if not exists allitebooks_livro_arquivo(
            autor text not null,
            isbn_10 text not null,
            ano_data text not null,
            idioma text not null,
            arquivo_tamanho text not null,
            arquivo_formato text not null,
            categoria text not null,
            pdf_url text not null,
            diretorio text not null,
            arquivo_nome text not null, 
            ja_baixado integer not null,
            
            livro_url text not null,

            primary key (pdf_url),
            foreign key (livro_url) references allitebooks_livro(livro_url)
        );
    """)




