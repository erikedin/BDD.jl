# Copyright 2018 Erik Edin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Experimental

struct GherkinSource
    lines::Vector{String}

    GherkinSource(source::String) = new(split(source, "\n"))
end

"""
    ParserInput

ParserInput encapsulates
- the Gherkin source
- the parser state (current line)
- the parser line operation (not implemented yet)
"""
struct ParserInput
    source::GherkinSource
    index::Int

    ParserInput(source::String) = new(GherkinSource(source), 1)
    ParserInput(input::ParserInput, index::Int) = new(input.source, index)
end

line(input::ParserInput) :: String = strip(input.source.lines[input.index])
consume(input::ParserInput) :: ParserInput = ParserInput(input, input.index + 1)

"""
    Parser{T}

A Parser{T} is a callable that takes a ParserInput and produces
a ParseResult{T}. The parameter T is the type of what it parses.
"""
abstract type Parser{T} end

"""
    ParseResult{T}

A ParseResult{T} is the either successful or failed result of trying to parse
a value of T from the input.
"""
abstract type ParseResult{T} end

"""
    OKParseResult{T}(value::T)

OKParseResult{T} is a successful parse result.
"""
struct OKParseResult{T} <: ParseResult{T}
    value::T
    newinput::ParserInput
end

"""
    BadParseResult{T}

BadParseResult{T} is an abstract supertype for all failed parse results.
"""
abstract type BadParseResult{T} <: ParseResult{T} end

struct BadExpectationParseResult{T} <: BadParseResult{T}
    expected::String
    actual::String
    newinput::ParserInput
end

"""
    Line(expected::String)

Line is a parser that recognizes when a line is exactly an expected value.
It returns the expected value if it is found, or a bad parse result if not.
"""
struct Line <: Parser{String}
    expected::String
end

function (parser::Line)(input::ParserInput) :: ParseResult{String}
    s = line(input)
    if s == parser.expected
        OKParseResult{String}(parser.expected, consume(input))
    else
        BadExpectationParseResult{String}(parser.expected, s, input)
    end
end

# Exports
export ParserInput, OKParseResult, BadParseResult

# Basic combinators
export Line

end