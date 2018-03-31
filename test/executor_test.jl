using Base.Test
using ExecutableSpecifications.Gherkin
using ExecutableSpecifications.Gherkin: ScenarioStep
using ExecutableSpecifications
using ExecutableSpecifications: StepDefinitionContext, StepDefinition, StepDefinitionLocation
using ExecutableSpecifications: Executor, StepExecutionResult, QuietRealTimePresenter, executefeature
import ExecutableSpecifications: present

successful_step_definition(::StepDefinitionContext) = ExecutableSpecifications.SuccessfulStepExecution()
failed_step_definition(::StepDefinitionContext) = ExecutableSpecifications.StepFailed()
error_step_definition(::StepDefinitionContext) = error("Some error")

struct FakeStepDefinitionMatcher <: ExecutableSpecifications.StepDefinitionMatcher
    steps::Dict{ExecutableSpecifications.Gherkin.ScenarioStep, Function}
end

ExecutableSpecifications.findstepdefinition(s::FakeStepDefinitionMatcher, step::ExecutableSpecifications.Gherkin.ScenarioStep) = StepDefinition("some text", s.steps[step], StepDefinitionLocation("", 0))

struct ThrowingStepDefinitionMatcher <: ExecutableSpecifications.StepDefinitionMatcher
    ex::Exception
end

ExecutableSpecifications.findstepdefinition(matcher::ThrowingStepDefinitionMatcher, ::ExecutableSpecifications.Gherkin.ScenarioStep) = throw(matcher.ex)

@testset "Executor        " begin
    @testset "Execute a one-step scenario; No matching step found; Result is NoStepDefinitionFound" begin
        stepdefmatcher = ThrowingStepDefinitionMatcher(ExecutableSpecifications.NoMatchingStepDefinition())
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [Given("some precondition")])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.NoStepDefinitionFound)
    end

    @testset "Execute a one-step scenario; The matching step is successful; Result is Successful" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Execute a one-step scenario; The matching step fails; Result is Failed" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.StepFailed)
    end

    @testset "Execute a one-step scenario; The matching step throws an error; Result is Error" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => error_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.UnexpectedStepError)
    end

    @testset "Execute a two-step scenario; First step throws an error; Second step is Skipped" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => error_step_definition,
                                                        when => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given, when])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SkippedStep)
    end

    @testset "Execute a two-step scenario; First step fails; Second step is Skipped" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition,
                                                        when => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given, when])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SkippedStep)
    end

    @testset "Execute a two-step scenario; Both steps succeed; All results are Success" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition,
                                                        when => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given, when])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Execute a three-step scenario; All steps succeeed; All results are Success" begin
        given = Given("Some precondition")
        when = When("some action")
        then = Then("some postcondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition,
                                                        when => successful_step_definition,
                                                        then => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given, when, then])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[3], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Execute a scenario; Scenario is provided; Scenario is returned with the result" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("This is a scenario", [], [given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test scenarioresult.scenario == scenario
    end

    @testset "Execute a scenario; No unique step definition found; Result is NonUniqueMatch" begin
        stepdefmatcher = ThrowingStepDefinitionMatcher(ExecutableSpecifications.NonUniqueStepDefinition([]))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [Given("some precondition")])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.NonUniqueMatch)
    end
end

mutable struct FakeRealTimePresenter <: ExecutableSpecifications.RealTimePresenter
    scenarios::Vector{Scenario}
    steps::Vector{ScenarioStep}
    results::Dict{ScenarioStep, StepExecutionResult}

    FakeRealTimePresenter() = new([], [], Dict())
end

present(p::FakeRealTimePresenter, scenario::Scenario) = push!(p.scenarios, scenario)
present(p::FakeRealTimePresenter, step::ScenarioStep) = push!(p.steps, step)
present(p::FakeRealTimePresenter, step::ScenarioStep, result::StepExecutionResult) = p.results[step] = result

stepresult(p::FakeRealTimePresenter, step::ScenarioStep) = p.results[step]

@testset "Executor Presentation" begin
    @testset "Execution presentation; Scenario is executed; Scenario is presented" begin
        presenter = FakeRealTimePresenter()
        matcher = FakeStepDefinitionMatcher(Dict())
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", [], [])
        ExecutableSpecifications.executescenario(executor, scenario)

        @test presenter.scenarios[1] == scenario
    end

    @testset "Execution presentation; Scenario has on Given; Given is presented" begin
        presenter = FakeRealTimePresenter()
        given = Given("some precondition")
        matcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", [], [given])
        ExecutableSpecifications.executescenario(executor, scenario)

        @test presenter.steps[1] == given
    end

    @testset "Execution presentation; Scenario step is successful; Step is presented as successful" begin
        presenter = FakeRealTimePresenter()
        given = Given("some precondition")
        matcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", [], [given])
        ExecutableSpecifications.executescenario(executor, scenario)

        @test stepresult(presenter, given) == ExecutableSpecifications.SuccessfulStepExecution()
    end

    @testset "Execution presentation; Scenario step fails; Next is also presented" begin
        presenter = FakeRealTimePresenter()
        given = Given("some precondition")
        when = When("some action")
        matcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition,
                                                 when => successful_step_definition))
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", [], [given, when])
        ExecutableSpecifications.executescenario(executor, scenario)

        @test presenter.steps[2] == when
    end

    @testset "Execution presentation; Scenario step fails; Next has result Skipped" begin
        presenter = FakeRealTimePresenter()
        given = Given("some precondition")
        when = When("some action")
        matcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition,
                                                 when => successful_step_definition))
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", [], [given, when])
        ExecutableSpecifications.executescenario(executor, scenario)

        @test stepresult(presenter, when) == ExecutableSpecifications.SkippedStep()
    end
end

@testset "Feature Executor" begin
    @testset "Execute a feature; Feature has one scenario; Feature has one scenario result" begin
        presenter = QuietRealTimePresenter()
        given = Given("some precondition")
        matcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        scenario = Scenario("some scenario", [], [given])
        featureheader = FeatureHeader("Some feature", [], [])
        feature = Feature(featureheader, [scenario])
        executor = Executor(matcher, presenter)

        featureresult = executefeature(executor, feature)

        @test length(featureresult.scenarioresults) == 1
    end
end