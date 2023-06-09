for Typ in (Base.TwicePrecision, AbstractChar, Complex)
    @eval begin
        RealInfinity(x::$Typ) = throw(MethodError(RealInfinity, x))
        ComplexInfinity{T}(x::$Typ) where T<:Real = throw(MethodError(ComplexInfinity{T}, x))
    end
end
ComplexInfinity{T}(x::ComplexInfinity{T}) where T<:Real = x

for op in (:<, :isless)
    @eval begin
        $op(s::RealInfinity, ::Infinity) = signbit(s)
        $op(s::RealInfinity, ::InfiniteCardinal{0}) = s < ∞
        $op(x::RealInfinity, ::InfiniteCardinal) = true
        $op(::Infinity, ::InfiniteCardinal{0}) = false
        $op(::Infinity, ::InfiniteCardinal) = true
        $op(x::InfiniteCardinal, ::Infinity) = false
        $op(x::InfiniteCardinal, ::RealInfinity) = false
        $op(::Infinity, ::RealInfinity) = false
        $op(s::ComplexInfinity{Bool}, ::Infinity) = signbit(s)
        $op(::Infinity, ::ComplexInfinity{Bool}) = false
        $op(::InfiniteCardinal{0}, ::InfiniteCardinal{0}) = false
        $op(::InfiniteCardinal, ::InfiniteCardinal{0}) = false
        $op(x::ComplexInfinity{Bool}, y::RealInfinity) = signbit(x) && !signbit(y)
        $op(x::RealInfinity, y::ComplexInfinity{Bool}) = signbit(x) && !signbit(y)
    end
end

for Typ in (Number, Complex, AbstractIrrational, BigFloat, ComplexInfinity, BigInt, Rational)
    @eval begin
        ==(x::RealInfinity, y::$Typ) = isinf(y) && angle(y) == angle(x)
        ==(y::$Typ, x::RealInfinity) = x == y
        ==(::InfiniteCardinal, y::$Typ) = ∞ == y
        ==(x::$Typ, ::InfiniteCardinal) = x == ∞
    end
end
==(::InfiniteCardinal, y::RealInfinity) = ∞ == y
==(x::RealInfinity, ::InfiniteCardinal) = x == ∞

const RealInfinityList = (Infinity, RealInfinity, InfiniteCardinal, ComplexInfinity{Bool})
for T1 in RealInfinityList
    for T2 in RealInfinityList
        @eval mod(::$T1, ::$T2) = NotANumber()
        @eval -(x::$T1, y::$T2) = x + (-y)
    end
    for T2 in (Complex, ComplexInfinity, Real, Rational, Complex{Bool}, Number)
        @eval begin
            -(x::$T1, y::$T2) = x + (-y)
            -(x::$T2, y::$T1) = x + (-y)
        end
    end
end


promote_rule(::Type{<:Infinity}, ::Type{<:Real}) = ExtendedReal
promote_rule(::Type{<:InfiniteCardinal}, ::Type{<:ExtendedReal}) = ExtendedReal
promote_rule(::Type{<:InfiniteCardinal}, ::Type{<:Real}) = ExtendedReal
Infinity(::InfiniteCardinal) = ∞
function ExtendedReal(x::Real)
    if isinf(x)
        RealInfinity(signbit(x))
    elseif isnan(x)
        throw(ArgumentError("Unable to convert $x to $ExtendedReal."))
    else
        RealFinite(x)
    end
end
ExtendedReal(x::Infinity) = ∞
ExtendedReal(x::RealInfinity) = x
ExtendedReal(x::InfiniteCardinal) = ∞
+(::RealFinite, ::Infinity) = ∞
+(::Infinity, ::RealFinite) = ∞
function *(::Infinity, x::RealFinite)
    if iszero(x)
        throw(ArgumentError("Unable to calculate $(x.value) * ∞"))
    else
        RealInfinity(signbit(x))
    end
end
*(x::RealFinite, y::Infinity) = y * x
<(::RealFinite, ::Infinity) = true
<(::Infinity, ::RealFinite) = false
<(::Infinity, ::Infinity) = false
≤(::RealFinite, ::Infinity) = true
≤(::Infinity, ::RealFinite) = false
≤(::Infinity, ::Infinity) = true
==(::RealFinite, ::Infinity) = false
max(::RealFinite, ::Infinity) = ∞
min(x::RealFinite, ::Infinity) = x.value

for op in (:(==), :max, :min)
    @eval $op(x::Infinity, y::RealFinite) = $op(y, x)
end