Require Import Basics.Overture Basics.Tactics.
Require Import WildCat.Core WildCat.Equiv.

(** * The wild 1-category of 0-groupoids. *)

(** Here we define a wild 1-category structure on the type of 0-groupoids.  We think of the 1-cells [g $== h] in a 0-groupoid [G] as a substitute for the paths [g = h], and so we closely follow the definitions used for the 1-category of types with [=] replaced by [$==].  In fact, the 1-category structure on types should be the pullback of the 1-category structure on 0-groupoids along a natural map [Type -> ZeroGpd] which sends [A] to [A] equipped with its path types.  A second motivating example is the 0-groupoid with underlying type [A -> B] and homotopies as the 1-cells.  The definitions chosen here exactly make the Yoneda lemma [opyon_equiv_0gpd] go through. *)

Record ZeroGpd := {
  carrier :> Type;
  isgraph_carrier : IsGraph carrier;
  is01cat_carrier : Is01Cat carrier;
  is0gpd_carrier : Is0Gpd carrier;  
}.

Global Existing Instance isgraph_carrier.
Global Existing Instance is01cat_carrier.
Global Existing Instance is0gpd_carrier.

Record Morphism_0Gpd (G H : ZeroGpd) := {
  fun_0gpd :> carrier G -> carrier H;
  is0functor_fun_0gpd : Is0Functor fun_0gpd;
}.

Global Existing Instance is0functor_fun_0gpd.

(** Now we show that the type [ZeroGpd] of 0-groupoids is itself a 1-category. *)
Global Instance isgraph_0gpd : IsGraph ZeroGpd.
Proof.
  apply Build_IsGraph.
  exact Morphism_0Gpd.
Defined.

Global Instance is01cat_0gpd : Is01Cat ZeroGpd.
Proof.
  srapply Build_Is01Cat.
  - intro G.
    snrapply Build_Morphism_0Gpd.
    1: exact idmap.
    snrapply Build_Is0Functor.
    intros g1 g2.
    exact idmap.
  - intros G H K f g.
    snrapply Build_Morphism_0Gpd.
    1: exact (f o g).
    snrapply Build_Is0Functor; cbn beta.
    intros g1 g2 p.
    apply is0functor_fun_0gpd, is0functor_fun_0gpd, p.
Defined.

Global Instance is2graph_0gpd : Is2Graph ZeroGpd.
Proof.
  intros G H.
  snrapply Build_IsGraph.
  intros f g.
  exact (forall x : G, f x $== g x).
Defined.

Global Instance is1cat_0gpd : Is1Cat ZeroGpd.
Proof.
  snrapply Build_Is1Cat.
  - intros G H.
    srapply Build_Is01Cat.
    + intro f. exact (fun x => Id (f x)).
    + intros f g h p q. exact (fun x => q x $@ p x).
  - intros G H.
    srapply Build_Is0Gpd.
    intros f g p. exact (fun x => (p x)^$).
  - intros G H K f.
    srapply Build_Is0Functor.
    intros g h p x.
    cbn.
    exact (fmap f (p x)).
  - intros G H K f.
    srapply Build_Is0Functor.
    intros g h p x.
    cbn.
    exact (p (f x)).
  - reflexivity.
  - reflexivity.
  - reflexivity.
Defined.

(** We define equivalences of 0-groupoids.  The definition is chosen to provide what is needed for the Yoneda lemma, and to match the concept for types, with paths replaced by 1-cells.  We are able to match the biinvertible definition.  The half-adjoint definition doesn't work, as we can't prove adjointification.  We would need to be in a 1-groupoid for that to be possible.  We could also use the "wrong" definition, without the eisadj condition, and things would go through, but it wouldn't match the definition for types. *)
Class IsEquiv_0Gpd {G H : ZeroGpd} (f : G $-> H) := {
  equiv_inv_0gpd : H $-> G;
  eisretr_0gpd : f $o equiv_inv_0gpd $== Id H;
  equiv_inv_0gpd' : H $-> G;
  eissect_0gpd' : equiv_inv_0gpd' $o f $== Id G;
}.

Arguments equiv_inv_0gpd {G H}%type_scope f {_}.
Arguments eisretr_0gpd {G H}%type_scope f {_} _.
Arguments equiv_inv_0gpd' {G H}%type_scope f {_}.
Arguments eissect_0gpd' {G H}%type_scope f {_} _.

Definition inverses_homotopic_0gpd {G H : ZeroGpd} (f : G $-> H) `{IsEquiv_0Gpd _ _ f}
  : equiv_inv_0gpd f $== equiv_inv_0gpd' f.
Proof.
  set (g := equiv_inv_0gpd f).
  set (g' := equiv_inv_0gpd' f).
  intro x.
  refine ((eissect_0gpd' f (g x))^$ $@ _); cbn.
  refine (fmap g' _).
  rapply eisretr_0gpd.
Defined.

Definition eissect_0gpd {G H : ZeroGpd} (f : G $-> H) `{IsEquiv_0Gpd _ _ f}
  : equiv_inv_0gpd f $o f $== Id G
  := (inverses_homotopic_0gpd f $@R f) $@ eissect_0gpd' f.

Record Equiv_0Gpd (G H : ZeroGpd) := {
  equiv_fun_0gpd :> Morphism_0Gpd G H;
  isequiv_equiv_0gpd : IsEquiv_0Gpd equiv_fun_0gpd;
}.

Global Instance hasequivs_0gpd : HasEquivs ZeroGpd.
Proof.
  srapply Build_HasEquivs; intros G H.
  1: exact (Equiv_0Gpd G H).
  all:intros f.
  - exact (IsEquiv_0Gpd f).
  - exact f.
  - cbn. exact (isequiv_equiv_0gpd _ _ f).
  - apply Build_Equiv_0Gpd.
  - intros; reflexivity.
  - exact (@equiv_inv_0gpd _ _ f (isequiv_equiv_0gpd _ _ f)).
  - cbn. apply eissect_0gpd.
  - cbn. apply eisretr_0gpd.
  - intros g r s; cbn beta.
    exact (Build_IsEquiv_0Gpd _ _ f g r g s).
Defined.

(* In fact, being an equivalence in the sense above is logically equivalent to being an equivalence in the sense of EquivGpd. *)

(* This is just a rough draft showing this.  Some further work is required to reorganize this. *)

Require Import WildCat.EquivGpd.

Definition IsEquiv0Gpd_Equiv_0Gpd {G H : ZeroGpd} (f : G $<~> H)
  : IsEquiv0Gpd f.
Proof.
  econstructor.
  - intro y.
    exists (f^-1$ y).
    rapply eisretr_0gpd.
  - intros x1 x2 m.
    exact ((eissect_0gpd f x1)^$ $@ fmap f^-1$ m $@ eissect_0gpd f x2).
Defined.

Definition Equiv_0Gpd_IsEquiv0Gpd {G H : ZeroGpd} (f : G -> H) `{!Is0Functor f}
  (e : IsEquiv0Gpd f)
  : G $<~> H.
Proof.
  destruct e as [e0 e1]; unfold SplEssSurj in e0.
  snrapply cate_adjointify.
  - exact (Build_Morphism_0Gpd _ _ f _).
  - snrapply Build_Morphism_0Gpd.
    1: exact (fun y => (e0 y).1).
    snrapply Build_Is0Functor; cbn beta.
    intros y1 y2 m.
    apply e1.
    exact ((e0 y1).2 $@ m $@ ((e0 y2).2)^$).
  - cbn.
    apply e0.
  - cbn.
    intro x.
    apply e1.
    apply e0.
Defined.
