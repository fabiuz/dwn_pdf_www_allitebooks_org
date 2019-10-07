import pdf_download_database
import os

var pdf_db: Database
try:
    pdf_db = newDatabase()
    pdf_db.setup()
except Exception:
    quit getCurrentException().msg

echo "Banco criado com sucesso!!!"

# Vamos corrigir algo no banco de dados, já baixamos alguns arquivos, então, precisamos
# atualizar isto no banco de dados.
# Pra realizar este procedimento, iremos obter todos os livros do banco de dados,
# e em seguida, iremos verificar se o arquivo do livro existe no diretório especificado.
var livros:seq[Livro]
if false == pdf_db.obterLivrosNaoBaixados(livros):
    echo "Não há nenhum livro pra ser baixado."

# Percorre cada livro e verifica se o arquivo existe.
for livro in livros:
    let arquivo = livro.diretorio & "/" & livro.arquivo_nome
    echo "Verificando se arquivo existe: \l\c" & arquivo
    if fileExists(arquivo):
        echo "Existe, atualizando..."
        let qt_registros = pdf_db.atualizarLivroJaBaixado(livro)
        echo "Qt de registros afetados: " & $qt_registros
    

