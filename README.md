# TINYclient, a tiny HTTP/JSON crud client toolkit


### Setup

TINYclient is based on [Curb](https://github.com/taf2/curb).

* Be sure that Curb/Curl works properly on your machine.
* install the gem

```sh
gem install tiny-client
```

### Getting Started


#### Configuration

You can initialize your API by extending the `TinyClient::Configuration`


```ruby
class MyConf < TinyClient::Configuration

  def initialize
    @url = 'http://localhost:3000/api/1.0'
    @headers = { 'Authorization' => 'token asdfasf4ffsafasdf@12rfsdfa' }  
  end
end

```

You can use that configuration in your resource. 


```ruby
class Author < TinyClient::Resource
  conf MyConf.instance
  
  path 'authors' # query will be made on http://localhost:3000/api/1.0/authors
  
  fields :id, :name # your resource attributes

  nested Books # your resource nested resource
end

class Book < TinyClient::Resource
  conf MyConf.instance
  path 'books'
  fields :id, :title
end
```

Now you will be able to do things like this: 

```ruby
author = Author.show(1) # Get /authors/1.json
author.name = 'P. K. D.'
author.save!   # PUT /authors/1.json { "author" : { "name" : "Bob" } }

book = Book.new
book.title = 'Confessions of a crap artist'
book = author.add_book(book) # POST /authors/1/books.json { "book" : { "title" : ".." }

book.id.present? # true

books = Book.index(limit: 10) # GET /books.json?limit=10

ed = Author.new
ed.name = 'Poe'
ed.save! # POST /authors.json { "author" : { "name" : "Poe" } }
ed.id.present?

ed_books = ed.books(limit: 10) # GET /authors/{ed.id}/books.json
first = ed_books.first
first.load! # GET /books/{first.id}.json
first.name.present?
```



