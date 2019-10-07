import httpclient
import uri
import strutils
import streams


#[
    When I insert url: "http://file.allitebooks.com/20150510/Sams Teach Yourself C++ in 24 Hours, 5th Edition.pdf"
    on the navigator firefox or chrome, this a showed:
    
    http://file.allitebooks.com/20150510/Sams%20Teach%20Yourself%20C++%20in%2024%20Hours,%205th%20Edition.pdf    

    But, when I try download of file of url:
        http://file.allitebooks.com/20150510/Sams Teach Yourself C++ in 24 Hours, 5th Edition.pdf,
        
        using getContent of httpClient, the error is displayed:
            Error: unhandled exception: 400 Bad Request [HttpRequestError]

        I try to using encodeUrl, this error is displayed:

            Error: unhandled exception: No uri scheme supplied. [ValueError]

        This question is:
            How to encode url similar to what is displayed in browser why using encode is giving error.
And how to pass 'scheme' to 'httpClient' ???
        
]#

var site_url = "http://file.allitebooks.com/20150510/Sams Teach Yourself C++ in 24 Hours, 5th Edition.pdf"
#site_url = site_url.replace(" ", "%20")
echo "site_url: " & site_url

var http_3 = newHttpClient()

var resposta = http_3.request(site_url)


if resposta.code != Http200:
    echo "Resposta: " & $resposta.code
    quit ("Erro ao acessar a url: " & site_url)

var arquivo = newFileStream("/tmp/teste.pdf", fmWrite)
var conteudo = resposta.bodyStream.readAll()
arquivo.write(conteudo)

#var http = newHttpClient()
#var http_content = http.getContent(site_url)  # This error => unhandled exception: 400 Bad Request [HttpRequestError]

#var http2 = newHttpClient()

# This error is: No uri scheme supplied. [ValueError]
# How to pass 'scheme' for 'httpClient' before of call getContent???
#var http_content_2 = http.getContent(encodeUrl(site_url))




