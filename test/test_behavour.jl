using MagneticReadHead
using Test

"""
    DemoException()
A custom exception type for testing that exceptions are thrown
"""
struct DemoException <: Exception
end

@testset "Should not block throwing errors" begin
    foo() = throw(DemoException())
    @test_throws(DemoException, (@debug foo()))
    
    
    bar() = map(_->foo(), 1:10)
    @test_throws(DemoException, (@debug foo()))

end
