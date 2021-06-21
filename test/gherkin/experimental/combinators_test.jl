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

@testset "Combinators          " begin
    @testset "Line" begin
        @testset "Match Foo; Foo; OK" begin
            # Arrange
            input = ParserInput("Foo")

            # Act
            p = Line("Foo")
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo"
        end

        @testset "Match Foo; Bar; Not OK" begin
            # Arrange
            input = ParserInput("Foo")

            # Act
            p = Line("Bar")
            result = p(input)

            # Assert
            @test result isa BadParseResult{String}
            @test result.expected == "Bar"
            @test result.actual == "Foo"
        end

        @testset "Match Foo, then Bar; Foo Bar; OK" begin
            # Arrange
            input = ParserInput("""
                Foo
                Bar
            """)

            # Act
            foo = Line("Foo")
            bar = Line("Bar")
            result1 = foo(input)
            result2 = bar(result1.newinput)

            # Assert
            @test result1 isa OKParseResult{String}
            @test result1.value == "Foo"
            @test result2 isa OKParseResult{String}
            @test result2.value == "Bar"
        end

        @testset "Match Foo, then Bar; Foo Baz; Not OK" begin
            # Arrange
            input = ParserInput("""
                Foo
                Baz
            """)

            # Act
            foo = Line("Foo")
            bar = Line("Bar")
            result1 = foo(input)
            result2 = bar(result1.newinput)

            # Assert
            @test result1 isa OKParseResult{String}
            @test result1.value == "Foo"
            @test result2 isa BadParseResult{String}
            @test result2.expected == "Bar"
            @test result2.actual == "Baz"
        end

        @testset "Match Foo; Bar; Not OK, state is unchanged" begin
            # Arrange
            input = ParserInput("Foo")

            # Act
            p = Line("Bar")
            result = p(input)

            # Assert
            @test result isa BadParseResult{String}
            @test result.newinput == input
        end
    end
end