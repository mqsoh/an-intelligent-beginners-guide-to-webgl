# An Intelligent Beginner's Guide to WebGL


###### WebGL Program
    console.log("Get ready to WebGL!");



# Compiling and Serving

After creating the following files, I'll be able to set up an auto-compiling,
auto-reloading web server that is running this WebGL program.

I wrote a literate programming tool called
[Knot](https://github.com/mqsoh/knot). It's distributed as a Docker image. It
can automatically compile this README into source code. I like to use Docker
Compose to do it.

###### file:docker-compose.yml
    knot:
      image: mqsoh/knot
      volumes:
        - .:/workdir
      command: watch README.md development.md

I'm going to serve this up with Brunch so I need to create a Docker image for
it.

###### file:Dockerfile
    FROM node:6

    RUN npm install -g brunch

    WORKDIR /workdir
    EXPOSE 3333
    EXPOSE 9485

    CMD ["brunch", "watch", "--server"]

I'll also use Docker Compose to serve the files.

###### file:docker-compose.yml
    brunch:
      build: .
      volumes:
        - .:/workdir
      ports:
        - "3333:3333"
        - "9485:9485"

If you look at [the development setup](./development.md), you'll see that I
need to provide a function called `my_code`. Since Brunch automatically
concatenates all JavaScript files into the `app.js`, I'll just dump this into a
file called `app/my_code.js`.

###### file:app/my_code.js
    exports.run = function run() {
        <<WebGL Program>>
    }



[Brunch]: http://brunch.io/
