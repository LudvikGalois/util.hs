module Util where

import Control.Applicative
import Control.Category
import Control.Monad
import Data.Bool
import Data.Foldable hiding (maximumBy, minimumBy)
import Data.Function (flip)
import Data.Functor.Classes
import Data.List.NonEmpty (NonEmpty (..))
import qualified Data.List.NonEmpty as NE
import Data.Maybe
import Data.Semigroup
import Data.Monoid (Monoid (..))
import Numeric.Natural

import Prelude (Enum (..), Bounded, Eq, Ord, Read, Show, Traversable (..), Ordering (..), uncurry)

infixr 3 &=&
(&=&) :: Applicative p => (a -> p b) -> (a -> p c) -> a -> p (b, c)
(&=&) = (liftA2 ∘ liftA2) (,)

infixr 3 *=*
(*=*) :: Applicative p => (a1 -> p b1) -> (a2 -> p b2) -> (a1, a2) -> p (b1, b2)
(f *=* g) (x, y) = liftA2 (,) (f x) (g y)

tripleK :: Applicative p => (a1 -> p b1) -> (a2 -> p b2) -> (a3 -> p b3) -> (a1, a2, a3) -> p (b1, b2, b3)
tripleK f g h (x, y, z) = liftA3 (,,) (f x) (g y) (h z)

infixr 2 <||>
(<||>) :: Applicative p => p Bool -> p Bool -> p Bool
(<||>) = liftA2 (||)

infixr 3 <&&>
(<&&>) :: Applicative p => p Bool -> p Bool -> p Bool
(<&&>) = liftA2 (&&)

liftA4 :: (Applicative p) => (a -> b -> c -> d -> e) -> p a -> p b -> p c -> p d -> p e
liftA4 f x y z = (<*>) (liftA3 f x y z)

apMA :: Monad m => m (a -> m b) -> a -> m b
apMA f = join ∘ ap f ∘ pure

whileJust :: (Alternative f, Monad m) => m (Maybe a) -> (a -> m b) -> m (f b)
whileJust mmx f = mmx >>= maybe (pure empty) (\ x -> (<|) <$> f x <*> whileJust mmx f)

untilJust :: Monad m => m (Maybe a) -> m a
untilJust mmx = mmx >>= maybe (untilJust mmx) pure

whenM :: Monad m => m Bool -> m () -> m ()
whenM p x = p >>= flip when x

unlessM :: Monad m => m Bool -> m () -> m ()
unlessM p x = p >>= flip unless x

list :: b -> (a -> [a] -> b) -> [a] -> b
list y f = list' y (liftA2 f NE.head NE.tail)

list' :: b -> (NonEmpty a -> b) -> [a] -> b
list' y _ []     = y
list' _ f (x:xs) = f (x:|xs)

infixr 9 &, ∘, ∘∘

(∘) :: (Category p) => p b c -> p a b -> p a c
(∘) = (.)

(&) :: (Category p) => p a b -> p b c -> p a c
(&) = flip (∘)

(∘∘) :: (c -> d) -> (a -> b -> c) -> (a -> b -> d)
(f ∘∘ g) x y = f (g x y)

infixl 0 `onn`
onn :: (a -> a -> a -> b) -> (c -> a) -> c -> c -> c -> b
onn f g x y z = f (g x) (g y) (g z)

fst3 :: (a, b, c) -> a
fst3 (x,_,_) = x

snd3 :: (a, b, c) -> b
snd3 (_,y,_) = y

þrd3 :: (a, b, c) -> c
þrd3 (_,_,z) = z

replicate :: Alternative f => Natural -> a -> f a
replicate 0 _ = empty
replicate n a = a <| replicate (pred n) a

replicateA :: (Applicative p, Alternative f) => Natural -> p a -> p (f a)
replicateA 0 _ = pure empty
replicateA n a = (<|) <$> a <*> replicateA (pred n) a

mtimesA :: (Applicative p, Semigroup a, Monoid a) => Natural -> p a -> p a
mtimesA n = unAp . stimes n . Ap

newtype Ap p a = Ap { unAp :: p a }
  deriving (Functor, Applicative, Monad, Alternative, MonadPlus, Foldable, Traversable,
            Eq1, Ord1, Read1, Show1, Eq, Ord, Read, Show, Bounded, Enum)
instance (Applicative p, Semigroup a) => Semigroup (Ap p a) where (<>) = liftA2 (<>)
instance (Applicative p, Semigroup a, Monoid a) => Monoid (Ap p a) where
    mempty = pure mempty
    mappend = (<>)

(!!?) :: Foldable f => f a -> Natural -> Maybe a
(!!?) = go . toList where go [] _ = Nothing
                          go (x:_) 0 = Just x
                          go (_:xs) n = go xs (pred n)

intercalate :: Semigroup a => a -> NonEmpty a -> a
intercalate a = sconcat . NE.intersperse a

bind2 :: Monad m => (a -> b -> m c) -> m a -> m b -> m c
bind2 f x y = liftA2 (,) x y >>= uncurry f

bind3 :: Monad m => (a -> b -> c -> m d) -> m a -> m b -> m c -> m d
bind3 f x y z = liftA3 (,,) x y z >>= uncurry3 f

traverse2 :: (Traversable t, Applicative t, Applicative p)
          => (a -> b -> p c) -> t a -> t b -> p (t c)
traverse2 f xs ys = sequenceA (f <$> xs <*> ys)

traverse3 :: (Traversable t, Applicative t, Applicative p)
          => (a -> b -> c -> p d) -> t a -> t b -> t c -> p (t d)
traverse3 f xs ys zs = sequenceA (f <$> xs <*> ys <*> zs)

foldMap2 :: (Foldable t, Applicative t, Monoid z)
         => (a -> b -> z) -> t a -> t b -> z
foldMap2 f xs ys = fold (f <$> xs <*> ys)

foldMap3 :: (Foldable t, Applicative t, Monoid z)
         => (a -> b -> c -> z) -> t a -> t b -> t c -> z
foldMap3 f xs ys zs = fold (f <$> xs <*> ys <*> zs)

uncurry3 :: (a -> b -> c -> d) -> (a, b, c) -> d
uncurry3 f (x, y, z) = f x y z

curry3 :: ((a, b, c) -> d) -> a -> b -> c -> d
curry3 f x y z = f (x, y, z)

infix 4 ∈, ∉
(∈), (∉) :: (Eq a, Foldable f) => a -> f a -> Bool
(∈) = elem
(∉) = not ∘∘ elem

maximumBy, minimumBy :: Foldable f => (a -> a -> Ordering) -> f a -> Maybe a
maximumBy f = foldr (\ a -> Just . fromMaybe a & \ b -> case f a b of GT -> a; _ -> b) Nothing
minimumBy f = foldr (\ a -> Just . fromMaybe a & \ b -> case f a b of LT -> a; _ -> b) Nothing

foldMapA :: (Applicative p, Monoid b, Foldable f) => (a -> p b) -> f a -> p b
foldMapA f = foldr (liftA2 mappend . f) (pure mempty)

altMap :: (Alternative p, Foldable f) => (a -> p b) -> f a -> p b
altMap f = foldr ((<|>) . f) empty

iterateM :: Monad m => Natural -> (a -> m a) -> a -> m (NonEmpty a)
iterateM 0 _ x = pure (x:|[])
iterateM k f x = (x NE.<|) <$> (f x >>= iterateM (pred k) f)

infixl 3 <|, |>

(<|) :: Alternative f => a -> f a -> f a
x <| xs = pure x <|> xs

(|>) :: Alternative f => f a -> a -> f a
xs |> x = xs <|> pure x
