## Synopsis

CodeSharing provides a simple specification for an Application Programming Interface, along with a sample implementation written in XQuery and designed for the eXist XML database, providing straightforward access both for applications and end-users to sample code from any XML encoding project. Also included is a package of XQuery, XSLT and related files that creates a simple interface designed for use in an XML database, developed and tested using the [eXist](http://exist-db.org) db.

## Example implementation

The [Map of Early Modern London](http://mapoflondon.uvic.ca) project provides an example installation of the CodeSharing interface [here](http://mapoflondon.uvic.ca/codesharing.htm). 

## Motivation

This project arises out of the [TEI](http://www.tei-c.org) encoding community. Although the TEI Guidelines are full of helpful examples, and other inititatives such as TEI By Example have made great progress in providing more access to samples of text-encoding to help beginners get started, there is no doubt that one of the biggest obstacles to encoders at many levels is finding out how other scholars and projects have chosen to encode a particular feature or use a specific tag or attribute. This project aims to provide a simple search engine for novice encoders to find examples of the use of particular elements and attributes within their project's source code. It also specifies an API which could be used to build harvesters which would gather examples of encoding from multiple repositories which provide CodeSharing services.

## Installation

Everything needed is in the `code` folder, and an instructions.txt file is provided to help you get started.

## API Reference

The API reference document is `code/codesharing_protocol.xhtml`.

## Contributors

Martin Holmes, Peter Stadler and Michael Joyce are the main contributors to this project.

## License

This project is dual-licensed under CC-by and BSD2 licences.
