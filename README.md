I've been working on this blob shader in Metal to get a head start on my Computer Graphics studies for my Computer Science degree. Even though we're going to use OpenGL at university, I wanted to learn Metal as well because it's more modern and feature-rich. plus, since it's Apple's graphics API, I might find a real use for it in the future.

The shader is quite simple; it uses the metaballs technique (multiple bubbles merging smoothly) to create this organic liquid effect. I also made the app look nice with Light and Dark Mode support, as well as mouse and keyboard interactions (you can push the blob with the cursor or press the spacebar to change its shape).

The code is well-commented, and I tried to make it as readable as possible, but I'm a beginner in computer graphics, so if there's anything that can be improved, please let me know.

btw, I used these resources to study:

- Paul Hudson's video on Metal shaders in SwiftUI, which explains very well how to connect everything ([https://www.youtube.com/watch?v=y3V4Hh8wKCc](https://www.youtube.com/watch?v=y3V4Hh8wKCc))
- The book "Metal by Tutorials" by Ray Wenderlich (now Kodeco) to understand the basics of how the GPU works ([https://www.kodeco.com/books/metal-by-tutorials](https://www.kodeco.com/books/metal-by-tutorials))
- Apple's official documentation, of course ([https://developer.apple.com/documentation/metal](https://developer.apple.com/documentation/metal)), and the Metal Shading Language manual ([https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf))
- And I also took a look at The Book of Shaders ([https://thebookofshaders.com/](https://thebookofshaders.com/)) to grasp the mathematical logic of fragment shaders

----

Eu estive fazendo esse shader de blob em Metal para adiantar os estudos de Computação Gráfica na minha graduação em Ciência da Computação, apesar de que na faculdade vamos usar OpenGL, mas eu queria aprender Metal também porque é mais moderno e tem mais recursos, e é a API gráfica da Apple, então eu poderia achar uma utilidade real para isso no futuro

O shader é bem simples, ele usa a técnica de metaballs (várias bolhas se juntando suavemente) pra criar esse efeito líquido e orgânico. Eu também fiz o app ficar bonitinho com suporte a light e dark mode, e interações com o mouse e teclado (dá pra empurrar o blob com o cursor ou apertar espaço pra ele mudar de forma)

O código é bem comentado e eu tentei deixar ele o mais legível possível, mas eu sou iniciante em computação gráfica, então se tiver alguma coisa que possa ser melhorada, por favor, me diga

Alias, eu usei esses conteudos aqui pra estudar

- o video do paul hudson sobre metal shaders no swiftui que explica muito bem como conectar tudo (<https://www.youtube.com/watch?v=y3V4Hh8wKCc>)
- o livro "metal by tutorials" do ray wenderlich (agora kodeco) pra entender a base de como a gpu funciona (<https://www.kodeco.com/books/metal-by-tutorials>)
- a documentacao oficial da apple claro (<https://developer.apple.com/documentation/metal>) e o manual da linguagem de shader (<https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf>)
- e tambem dei uma olhada no the book of shaders (<https://thebookofshaders.com/>) pra pegar a logica matematica dos fragment shaders
