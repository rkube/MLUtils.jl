using MLUtils: obsview

@testset "BatchView" begin

    @testset "constructor" begin
        @test_throws DimensionMismatch BatchView((rand(2,10),rand(9)))
        @test_throws DimensionMismatch BatchView((rand(2,10),rand(9)))
        @test_throws DimensionMismatch BatchView((rand(2,10),rand(4,9,10),rand(9)))
        @test_throws MethodError BatchView(EmptyType())
        for var in (vars..., tuples..., Xs, ys)
            @test_throws MethodError BatchView(var...)
            @test_throws MethodError BatchView(var, 16)

            A = BatchView(var, batchsize=3)
            @test length(A) == 5
            @test batchsize(A) == 3
            @test numobs(A) == length(A)
            @test @inferred(parent(A)) === var
        end
        A = BatchView(X, batchsize=16)
        @test length(A) == 1
        @test batchsize(A) == 15
    end


    @testset "typestability" begin
        for var in (vars..., tuples..., Xs, ys), batchsize in (1, 3), partial in (true, false), collate in (Val(true), Val(false), Val(nothing))
            @test typeof(@inferred(BatchView(var; batchsize, partial, collate))) <: BatchView
        end
        @test typeof(@inferred(BatchView(CustomType()))) <: BatchView
    end

    @testset "AbstractArray interface" begin
        for var in (vars..., tuples..., Xs, ys)
            A = BatchView(var, batchsize=5)
            @test_throws BoundsError A[-1]
            @test_throws BoundsError A[4]
            @test @inferred(numobs(A)) == 3
            @test @inferred(length(A)) == 3
            @test @inferred(batchsize(A)) == 5
            @test @inferred(size(A)) == (3,)
            @test @inferred(getobs(A[2:3])) == getobs(BatchView(ObsView(var, 6:15), batchsize=5))
            @test @inferred(getobs(A[[1,3]])) == getobs(BatchView(ObsView(var, [1:5..., 11:15...]), batchsize=5))
            @test @inferred(A[1]) == obsview(var, 1:5)
            @test @inferred(A[2]) == obsview(var, 6:10)
            @test @inferred(A[3]) == obsview(var, 11:15)
            @test A[end] == A[3]
            @test @inferred(getobs(A,1)) == getobs(var, 1:5)
            @test @inferred(getobs(A,2)) == getobs(var, 6:10)
            @test @inferred(getobs(A,3)) == getobs(var, 11:15)
            @test typeof(@inferred(collect(A))) <: Vector
        end
        for var in (vars..., tuples...)
            A = BatchView(var, batchsize=5)
            @test @inferred(getobs(A)) == var
            @test A[2:3] == obsview(var, [6:15;])
            @test A[[1,3]] == obsview(var, [1:5..., 11:15...])
        end
    end


    @testset "subsetting" begin
        # for var in (vars..., tuples..., Xs, ys)
            for var in (vars[1], )
            A = BatchView(var, batchsize=3)
            @test getobs(@inferred(ObsView(A))) == @inferred(getobs(A))
            @test_throws BoundsError ObsView(A,1:6)

            S = @inferred(ObsView(A, 1:2))
            @test typeof(S) <: ObsView
            @test @inferred(numobs(S)) == 2
            @test @inferred(length(S)) == numobs(S)
            @test @inferred(size(S)) == (length(S),)
            @test getobs(@inferred(A[1:2])) == getobs(S)
            @test @inferred(getobs(A,1:2)) == getobs(S)
            @test @inferred(getobs(S)) == getobs(BatchView(ObsView(var,1:6),batchsize=3))

            S = @inferred(ObsView(A, 1:2))
            @test typeof(S) <: ObsView
        end
        A = BatchView(X, batchsize=3)
        @test typeof(A.data) <: Array
        S = @inferred(obsview(A))
        S === A
    end

    # @testset "nesting with ObsView" begin
    #     for var in vars
    #         @test eltype(@inferred(BatchView(ObsView(var)))[1]) <: Union{SubArray,String}
    #     end
    #     for var in tuples
    #         @test eltype(@inferred(BatchView(ObsView(var)))[1]) <: Tuple
    #     end
    #     for var in (Xs, ys)
    #         @test eltype(@inferred(BatchView(ObsView(var)))[1]) <: SubArray
    #     end
    # end
end
