FROM ruby:3.0-alpine

LABEL maintainer="Lee Folkman <lee.folkman@gmail.com>"

ENV GEM_HOME /htcc

RUN mkdir $GEM_HOME
WORKDIR $GEM_HOME

COPY ./htcc.gemspec ./irb.sh $GEM_HOME/
COPY ./lib $GEM_HOME/lib

RUN gem build htcc.gemspec
RUN gem install *.gem
