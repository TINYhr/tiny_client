# TINYclient, a tiny HTTP/JSON crud client toolkit
[![Gem Version](https://badge.fury.io/rb/tp_client.svg)](https://badge.fury.io/rb/tp_client) [![Build Status](https://travis-ci.org/TINYhr/tiny_client.svg)](https://travis-ci.org/TINYhr/tiny_client) [![Code Climate](https://codeclimate.com/github/TINYhr/tiny_client/badges/gpa.svg)](https://codeclimate.com/github/TINYhr/tiny_client)

TINYclient is inspired by [Active Record](http://guides.rubyonrails.org/active_record_basics.html) and based on [Curb](https://github.com/taf2/curb).

### Setup

* Be sure that Curb/Curl works properly on your machine.
* install the gem

```sh
gem install tp_client
```

* Or in Gemfile

```ruby
# As gem main class is different from gem name, we must require file name explicitly
gem 'tp_client', '~> 0.2.7', require: 'tiny_client'
```

Please notice, we have 2 similar gems:

* [tp_client](https://rubygems.org/gems/tp_client) active, maintained by TINYpulse
* [tiny_client](https://rubygems.org/gems/tiny_client) inactive. **PLEASE DO NOT USE tiny_client GEM**.

### Getting Started


#### Configuration

You can initialize your API by extending the `TinyClient::Configuration`


```ruby
class MyConf < TinyClient::Configuration
  def initialize
    @url = 'http://localhost:3000/api/1.0'
    @headers = { 'Authorization' => 'token asdfasf4ffsafasdf@12rfsdfa' }
    @limit = 100
    @connect_timeout = 30 # seconds
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

#### Usage

Now you will be able to this:

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

# You can also navigate through all resources

Author.index_all do |author| # It will retrieve all the authors, using limit, and offset query params to paginate
 # Do something for each author
end


Author.index_in_batches(limit: 1000) do |authors|
  # retrieve authors by batch of 1000
end

```

### Instance methods behavior

#### load!

It will perform a get request on the resource id and set the resource fields value to the value retrived by the response.

```
author.load! # GET /authors/{author.id}.json ->  { id: 1, name: 'Toto' ... }
author.name # 'Toto'
```

#### save!

It will create the resource if `id` is not set, otherwise it will update it.
The resource fields value will be updated by the response body content.

```
toto = MyModule::Author.new
toto.save! # POST /authors.json { author: {} }

toto.id # should have been set by through the reponse

toto.name = 'Toto'
toto.save! # PUT {author: {name: 'Toto'}} -> /authors/{toto.id}.json
```

Only `changed` values will be passed through the body content.

You can `clear` changes with `#clear_changes!`
You can now which fields has been marked has changed with `#changes`

Changes is automatically clear when you perform a request ( i.e call, `#show #index #get #put #post save!` and so on)

### Nested resource

You can add a nested resource thanks to the `nested` class methods.

```ruby
class Author < TinyClient::Resource
  nested Books, Magazines
end
```

It will allows you to call your nested resource directly from an instance of your parent resource.

```ruby
author = Author.show(1)
author.books(limit: 100)  # index GET /authors/1/books.json?limit=100
book = author.book(1)     # show  GET/authors/1/books/1.json
book.title = 'New title'
author.update_book(book)  # update  PUT /authors/1/books/1.json -- { 'book': { 'title': 'New title' } }
author.remove_book(book)  # destroy DELETE /authors/1/books/1.json
author.add_book(book)     # create  POST /author/1/books.json -- { 'book': { 'title': 'New title' } }
author.books_all.each     # x GET /authors/1/books.json?limit=.. -- Enumerator -- Retrieve ALL books using limit and offset to handle pagination
```

This is equivalent to the following:

```ruby
author = Author.show(1)
author.nested_index(Book, limit: 100)
book = author.nested_show(Book, 1)
book.title = 'New title'
author.nested_update(book)
author.nested_delete(book)
author.nested_create(book)
author.nested_all(Book, limit: 10) # retrieve all books, quering the server by batch of 10;
```

### Constraint & Support

#### JSON only

TinyClient supports only JSON data.
`Accept: application/json` header is set.

#### POST/PUT create/update

The content passed to the server will always be prefixed by the class name in lower case.

```
toto = MyModule::Author.new
toto.save! # POST { author: {} }

```

#### Pagination / Buffer

Pagination, buffer is achieve through `limit` and `offset` params.

```
Author.index_all(limit: 100) # Will queries the server by batch of 100, until all authors has been retrieved through the enumerator.

```

#### Content-Encoding support

TinyClient support `gzip` Content-Encoding. Response with `gzip` Content-Encoding will be automatically decompressed.
You can set the `Accept-Encoding: gzip` through the configuration headers.

### Development

You can run the test using:

```shell
rake
```
