module Infinities

import Base: angle, isone, iszero, isinf, isfinite, abs, one, oneunit, zero, isless,
                +, -, *, ==, <, ≤, >, ≥, fld, cld, div, mod, min, max, sign, signbit,
                string, show, promote_rule, convert, getindex

export ∞,  ℵ₀,  ℵ₁, RealInfinity, ComplexInfinity, InfiniteCardinal, NotANumber
# The following is commented out for now to avoid conflicts with Infinity.jl
# export Infinity

"""
NotANumber()

represents something that is undefined, for example, `0 * ∞`.
"""
struct NotANumber <: Number end


"""
   Infinity()

represents the positive real infinite.
"""
struct Infinity <: Real end

const ∞ = Infinity()

show(io::IO, ::Infinity) = print(io, "∞")
string(::Infinity) = "∞"

_convert(::Type{Float64}, ::Infinity) = Inf64
_convert(::Type{Float32}, ::Infinity) = Inf32
_convert(::Type{Float16}, ::Infinity) = Inf16
_convert(::Type{T}, ::Infinity) where {T<:Real} = convert(T, Inf)::T
(::Type{T})(x::Infinity) where {T<:Real} = _convert(T, x)


sign(y::Infinity) = 1
angle(x::Infinity) = 0
signbit(::Infinity) = false

one(::Type{Infinity}) = 1
oneunit(::Type{Infinity}) = 1
oneunit(::Infinity) = 1
zero(::Infinity) = 0

isinf(::Infinity) = true
isfinite(::Infinity) = false

for OP in (:fld,:cld,:div)
  @eval begin
    $OP(::Infinity, ::Real) = ∞
    $OP(::Infinity, ::Infinity) = NotANumber()
  end
end

div(::T, ::Infinity) where T<:Real = zero(T)
fld(x::T, ::Infinity) where T<:Real = signbit(x) ? -one(T) : zero(T)
cld(x::T, ::Infinity) where T<:Real = signbit(x) ? zero(T) : one(T)

struct RealInfinity <: Real
    signbit::Bool
end

RealInfinity() = RealInfinity(false)
RealInfinity(::Infinity) = RealInfinity()
RealInfinity(x::RealInfinity) = x

isinf(::RealInfinity) = true
isfinite(::RealInfinity) = false

promote_rule(::Type{Infinity}, ::Type{RealInfinity}) = RealInfinity
_convert(::Type{RealInfinity}, ::Infinity) = RealInfinity(false)

_convert(::Type{Float16}, x::RealInfinity) = sign(x)*Inf16
_convert(::Type{Float32}, x::RealInfinity) = sign(x)*Inf32
_convert(::Type{Float64}, x::RealInfinity) = sign(x)*Inf64
_convert(::Type{T}, x::RealInfinity) where {T<:Real} = sign(x)*convert(T, Inf)
(::Type{T})(x::RealInfinity) where {T<:Real} = _convert(T, x)

for Typ in (RealInfinity, Infinity)
    @eval Bool(x::$Typ) = throw(InexactError(:Bool, Bool, x))
end

signbit(y::RealInfinity) = y.signbit
sign(y::RealInfinity) = 1-2signbit(y)
angle(x::RealInfinity) = π*signbit(x)

string(y::RealInfinity) = signbit(y) ? "-∞" : "+∞"
show(io::IO, y::RealInfinity) = print(io, string(y))

######
# ComplexInfinity
#######

# angle is π*a where a is (false==0) and (true==1)

"""
ComplexInfinity(signbit)

represents an infinity in the complex plane with the angle
specified by `π * signbit`. The use of the name `signbit` is
for consistency with `RealInfinity`.
"""
struct ComplexInfinity{T<:Real} <: Number
    signbit::T
end

ComplexInfinity{T}() where T = ComplexInfinity(zero(T))
ComplexInfinity() = ComplexInfinity{Bool}()
ComplexInfinity{T}(::Infinity) where T<:Real = ComplexInfinity{T}()
ComplexInfinity(::Infinity) = ComplexInfinity()
ComplexInfinity{T}(x::RealInfinity) where T<:Real = ComplexInfinity{T}(signbit(x))
ComplexInfinity(x::RealInfinity) = ComplexInfinity(signbit(x))
ComplexInfinity{T}(x::ComplexInfinity) where T<:Real = ComplexInfinity(T(signbit(x)))

isinf(::ComplexInfinity) = true
isfinite(::ComplexInfinity) = false
signbit(y::ComplexInfinity{Bool}) = y.signbit
signbit(y::ComplexInfinity{<:Integer}) = !(mod(y.signbit,2) == 0)
signbit(y::ComplexInfinity) = y.signbit

promote_rule(::Type{Infinity}, ::Type{ComplexInfinity{T}}) where T = ComplexInfinity{T}
promote_rule(::Type{RealInfinity}, ::Type{ComplexInfinity{T}}) where T = ComplexInfinity{T}
promote_rule(::Type{ComplexInfinity{T}}, ::Type{ComplexInfinity{S}}) where {T, S} = ComplexInfinity{promote_type(T, S)}
convert(::Type{ComplexInfinity{T}}, ::Infinity) where T = ComplexInfinity{T}()
convert(::Type{ComplexInfinity}, ::Infinity) = ComplexInfinity()
convert(::Type{ComplexInfinity{T}}, x::RealInfinity) where T = ComplexInfinity{T}(x)
convert(::Type{ComplexInfinity}, x::RealInfinity) = ComplexInfinity(x)


sign(y::ComplexInfinity{<:Integer}) = mod(y.signbit,2) == 0 ? 1 : -1
angle(x::ComplexInfinity) = π*x.signbit

show(io::IO, x::ComplexInfinity) = print(io, "exp($(x.signbit)*im*π)∞")

for OP in (:fld,:cld,:div)
  @eval $OP(y::ComplexInfinity, a::Number) = y*(1/sign(a))
end

Base.hash(::Infinity) = 0x020113134b21797f # made up


include("cardinality.jl")
include("interface.jl")
include("compare.jl")
include("algebra.jl")
include("ambiguities.jl")
end # module
