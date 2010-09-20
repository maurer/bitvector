module Data.BitVector where

open import Data.Vec
open import Data.Nat hiding (pred) renaming (_+_ to _N+_; _*_ to _N*_; zero to Nzero; suc to Nsuc; _≤_ to _N≤_; _≟_ to _N≟_; _≤?_ to _N≤?_; _<_ to _N<_ ;compare to compareℕ) 
open import Relation.Binary.PropositionalEquality
open import Algebra.FunctionProperties.Core
open import Data.Product


open import Data.Bool public hiding (_≟_) renaming (Bool to Bit; false to 0#; true to 1#)

infixl 6 _+_
infixl 7 _*_

BitVector = Vec Bit

bitwise-and : ∀ {n} → Op₂ (BitVector n)
bitwise-and = zipWith _∧_

bitwise-or : ∀ {n} → Op₂ (BitVector n)
bitwise-or = zipWith _∨_

half-adder : Bit → Bit → Bit × Bit
half-adder x y = x xor y , x ∧ y

full-adder : Bit → Bit → Bit → Bit × Bit
full-adder a b c0 with half-adder a b
... | s0 , c1 with half-adder s0 c0
... | s1 , c2 = s1 , c1 ∨ c2

add′ : ∀ {n} → Bit → BitVector n → BitVector n → BitVector n
add′ c [] [] = []
add′ c (x ∷ xs) (y ∷ ys) with full-adder x y c
... | s , cout = s ∷ add′ cout xs ys

_+_ : ∀ {n} → Op₂ (BitVector n)
x + y = add′ 0# x y

zero : ∀ n → BitVector n
zero Nzero = []
zero (Nsuc n) = 0# ∷ (zero n)

one : ∀ n → BitVector n
one Nzero = []
one (Nsuc n) = 1# ∷ zero n

bitwise-negation : ∀ {n} → Op₁ (BitVector n)
bitwise-negation = Data.Vec.map not

ones : ∀ n → BitVector n
ones n = bitwise-negation (zero n)

droplast : ∀ {n} → BitVector (Nsuc n) → BitVector n
droplast {Nzero} _ = []
droplast {Nsuc n} (x ∷ xs) = x ∷ droplast xs

shift : ∀ {n} → Op₁ (BitVector n)
shift {Nzero} xs = xs
shift {Nsuc n} xs = 0# ∷ droplast xs


_*_ : ∀ {n} → Op₂ (BitVector n)
[] * [] = []
(0# ∷ xs) * yys = 0# ∷ xs * droplast yys
(1# ∷ xs) * yys = yys + (0# ∷ xs * droplast yys)



-_ : ∀ {n} → Op₁ (BitVector n)
- x = one _ + bitwise-negation x
 
val10 = 0# ∷ 1# ∷ 0# ∷ 1# ∷ 0# ∷ 0# ∷ 0# ∷ 0# ∷ []
val11 = 1# ∷ 1# ∷ 0# ∷ 1# ∷ 0# ∷ 0# ∷ 0# ∷ 0# ∷ []

open import Relation.Nullary
open import Relation.Binary


infix 4 _≟_

_≟_ : ∀ {n} → Decidable {A = BitVector n} _≡_
[] ≟ [] = yes refl
x ∷ xs ≟ y ∷ ys with xs ≟ ys 
0# ∷ xs ≟ 0# ∷ .xs | yes refl = yes refl
1# ∷ xs ≟ 1# ∷ .xs | yes refl = yes refl
1# ∷ xs ≟ 0# ∷ ys  | yes _ = no λ()
0# ∷ xs ≟ 1# ∷ ys  | yes _ = no λ()
...                | no pf = no (λ q → pf (cong tail q))


-- I should just parametrize the entire module by the size... maybe later though
module Order where
  open import Data.Sum
  infix 4 _q≤_ 

  -- Silly agda bug is preventing me from using the _≤_ name even though it's not in scope :(
  data _q≤_ : ∀ {n} → BitVector n → BitVector n → Set where
    []≤[] : [] q≤ []
    0#≤n  : ∀ {n} {x y : BitVector n} {b} → (pf : x q≤ y) → (0# ∷ x) q≤ (b ∷ y)
    1#≤1# : ∀ {n} {x y : BitVector n} → (pf : x q≤ y) → (1# ∷ x) q≤ (1# ∷ y)

  _≤?_ : ∀ {n} → Decidable (_q≤_ {n})
  [] ≤? [] = yes []≤[]
  (x  ∷ xs) ≤? (y  ∷ ys) with xs ≤? ys
  (0# ∷ xs) ≤? (0# ∷ ys)    | yes pf = yes (0#≤n pf)
  (0# ∷ xs) ≤? (1# ∷ ys)    | yes pf = yes (0#≤n pf)
  (1# ∷ xs) ≤? (0# ∷ ys)    | yes pf = no  (λ ())
  (1# ∷ xs) ≤? (1# ∷ ys)    | yes pf = yes (1#≤1# pf)
  (0# ∷ xs) ≤? (y  ∷ ys)    | no  pf = no  (λ q → pf (helper q))
    -- I wanna pattern-match in lambdas dammit
    where helper : 0# ∷ xs q≤ y ∷ ys → xs q≤ ys
          helper (0#≤n pf) = pf
  (1# ∷ xs) ≤? (0# ∷ ys)    | no  pf = no  (λ ())
  (1# ∷ xs) ≤? (1# ∷ ys)    | no  pf = no  (λ q → pf (helper q))
    where helper : 1# ∷ xs q≤ 1# ∷ ys → xs q≤ ys
          helper (1#≤1# pf) = pf

  refl′ : ∀ {n} → _≡_ ⇒ (_q≤_ {n})
  refl′ {0} {[]} refl = []≤[]
  refl′ {Nsuc n} {0# ∷ xs} refl = 0#≤n (refl′ refl)
  refl′ {Nsuc n} {1# ∷ xs} refl = 1#≤1# (refl′ refl)

  antisym : ∀ {n} → Antisymmetric _≡_ (_q≤_ {n})
  antisym []≤[] q = refl
  antisym (0#≤n pf₀) (0#≤n pf₁) rewrite antisym pf₀ pf₁ = refl
  antisym (1#≤1# pf₀) (1#≤1# pf₁) rewrite antisym pf₀ pf₁ = refl

  trans′ : ∀ {n} → Transitive (_q≤_ {n})
  trans′ []≤[] []≤[] = []≤[]
  trans′ (0#≤n pf₀) (0#≤n pf₁)  = 0#≤n (trans′ pf₀ pf₁)
  trans′ (0#≤n pf₀) (1#≤1# pf₁) = 0#≤n (trans′ pf₀ pf₁)
  trans′ (1#≤1# pf₀) (1#≤1# pf₁) = 1#≤1# (trans′ pf₀ pf₁)

{-
  total : ∀ {n} → Total (_q≤_ {n})
  total [] [] = inj₁ []≤[]
  total (0# ∷ xs) (y  ∷ ys) with total xs ys
  total (0# ∷ xs) (y  ∷ ys) | inj₁ pf = inj₁ (0#≤n pf)
  total (0# ∷ xs) (0# ∷ ys) | inj₂ pf = inj₂ (0#≤n pf)
  total (0# ∷ xs) (1# ∷ ys) | inj₂ pf = {!!}
  total (1# ∷ xs) (y  ∷ ys) with total ys xs
  total (1# ∷ xs) (0# ∷ ys) | inj₁ pf = inj₂ (0#≤n pf)
  total (1# ∷ xs) (1# ∷ ys) | inj₁ pf = inj₂ (1#≤1# pf)
  total (1# ∷ xs) (0# ∷ ys) | inj₂ pf = {!!}
  total (1# ∷ xs) (1# ∷ ys) | inj₂ pf = inj₁ (1#≤1# pf)
-}