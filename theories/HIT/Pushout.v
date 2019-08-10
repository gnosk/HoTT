(* -*- mode: coq; mode: visual-line -*- *)
Require Import HoTT.Basics.
Require Import HoTT.Types.
Require Import HSet TruncType.
Require Export HIT.Coeq.
Require Import HIT.Truncations.
Local Open Scope path_scope.


(** * Homotopy Pushouts *)

(*
Record Span :=
  { A : Type; B : Type; C : Type;
    f : C -> A;
    g : C -> B }.

Record Cocone (S : Span) (D : Type) :=
  { i : A S -> D;
    j : B S -> D;
    h : forall c, i (f S c) = j (g S c) }.
*)

(** We define pushouts in terms of coproducts and coequalizers. *)

Definition pushout {A B C : Type} (f : A -> B) (g : A -> C) : Type
  := Coeq (inl o f) (inr o g).

Definition push {A B C : Type} {f : A -> B} {g : A -> C}
 : B+C -> pushout f g
  := @coeq _ _ (inl o f) (inr o g).

Definition pushl {A B C} {f : A -> B} {g : A -> C} (b : B) : pushout f g := push (inl b).
Definition pushr {A B C} {f : A -> B} {g : A -> C} (c : C) : pushout f g := push (inr c).

Definition pp {A B C : Type} {f : A -> B} {g : A -> C} (a : A) : pushl (f a) = pushr (g a)
  := @cp A (B+C) (inl o f) (inr o g) a.

(* Some versions with explicit parameters. *)
Definition pushl' {A B C} (f : A -> B) (g : A -> C) (b : B) : pushout f g := pushl b.
Definition pushr' {A B C} (f : A -> B) (g : A -> C) (c : C) : pushout f g := pushr c.
Definition pp' {A B C : Type} (f : A -> B) (g : A -> C) (a : A) : pushl (f a) = pushr (g a)
  := pp a.

Section PushoutInd.

  Context {A B C : Type} {f : A -> B} {g : A -> C} (P : pushout f g -> Type)
          (pushb : forall b : B, P (pushl b))
          (pushc : forall c : C, P (pushr c))
          (pusha : forall a : A, (pp a) # (pushb (f a)) = pushc (g a)).

  Definition pushout_ind
    : forall (w : pushout f g), P w
    := Coeq_ind P (fun bc => match bc with inl b => pushb b | inr c => pushc c end) pusha.

  Definition pushout_ind_beta_pushl (b:B) : pushout_ind (pushl b) = pushb b
    := 1.
  Definition pushout_ind_beta_pushr (c:C) : pushout_ind (pushr c) = pushc c
    := 1.

  Definition pushout_ind_beta_pp (a:A)
    : apD pushout_ind (pp a) = pusha a
    := Coeq_ind_beta_cp P (fun bc => match bc with inl b => pushb b | inr c => pushc c end) pusha a.

End PushoutInd.

(** But we want to allow the user to forget that we've defined pushouts in terms of coequalizers. *)
Arguments pushout : simpl never.
Arguments push : simpl never.
Arguments pp : simpl never.
Arguments pushout_ind : simpl never.
Arguments pushout_ind_beta_pp : simpl never.

Definition pushout_rec {A B C} {f : A -> B} {g : A -> C} (P : Type)
  (pushb : B -> P)
  (pushc : C -> P)
  (pusha : forall a : A, pushb (f a) = pushc (g a))
  : @pushout A B C f g -> P
  := pushout_ind (fun _ => P) pushb pushc (fun a => transport_const _ _ @ pusha a).

Definition pushout_rec_beta_pp {A B C f g} (P : Type)
  (pushb : B -> P)
  (pushc : C -> P)
  (pusha : forall a : A, pushb (f a) = pushc (g a))
  (a : A)
  : ap (pushout_rec P pushb pushc pusha) (pp a) = pusha a.
Proof.
  unfold pushout_rec.
  eapply (cancelL (transport_const (pp a) _)).
  refine ((apD_const (@pushout_ind A B C f g (fun _ => P) pushb pushc _) (pp a))^ @ _).
  refine (pushout_ind_beta_pp (fun _ => P) _ _ _ _).
Defined.

(** ** Universal property *)

Definition pushout_unrec {A B C P} (f : A -> B) (g : A -> C)
           (h : pushout f g -> P)
  : {psh : (B -> P) * (C -> P) &
           forall a, fst psh (f a) = snd psh (g a)}.
Proof.
  exists (h o pushl , h o pushr).
  intros a; cbn.
  exact (ap h (pp a)).
Defined.

Definition isequiv_pushout_rec `{Funext} {A B C} (f : A -> B) (g : A -> C) P
  : IsEquiv (fun p : {psh : (B -> P) * (C -> P) &
                            forall a, fst psh (f a) = snd psh (g a) }
             => pushout_rec P (fst p.1) (snd p.1) p.2).
Proof.
  srefine (isequiv_adjointify _ (pushout_unrec f g) _ _).
  - intros h.
    apply path_arrow; intros x.
    srefine (pushout_ind (fun x => pushout_rec P (fst (pushout_unrec f g h).1) (snd (pushout_unrec f g h).1) (pushout_unrec f g h).2 x = h x) _ _ _ x).
    + intros b; reflexivity.
    + intros c; reflexivity.
    + intros a; cbn.
      abstract (rewrite transport_paths_FlFr, pushout_rec_beta_pp;
                rewrite concat_p1; apply concat_Vp).
  - intros [[pushb pushc] pusha]; unfold pushout_unrec; cbn.
    srefine (path_sigma' _ _ _).
    + srefine (path_prod' _ _); reflexivity.
    + apply path_forall; intros a.
      abstract (rewrite transport_forall_constant, pushout_rec_beta_pp;
                reflexivity).
Defined.

Definition equiv_pushout_rec `{Funext} {A B C} (f : A -> B) (g : A -> C) P
  : {psh : (B -> P) * (C -> P) &
           forall a, fst psh (f a) = snd psh (g a) }
      <~> (pushout f g -> P)
  := BuildEquiv _ _ _ (isequiv_pushout_rec f g P).

Definition equiv_pushout_unrec `{Funext} {A B C} (f : A -> B) (g : A -> C) P
  : (pushout f g -> P)
      <~> {psh : (B -> P) * (C -> P) &
                 forall a, fst psh (f a) = snd psh (g a) }
  := equiv_inverse (equiv_pushout_rec f g P).

(** ** Symmetry *)

Definition pushout_sym_map {A B C} {f : A -> B} {g : A -> C}
  : pushout f g -> pushout g f
  := pushout_rec (pushout g f) pushr pushl (fun a : A => (pp a)^).

Lemma sect_pushout_sym_map {A B C f g} : Sect (@pushout_sym_map A C B g f) (@pushout_sym_map A B C f g).
Proof.
  unfold Sect. srapply @pushout_ind.
  - intros; reflexivity.
  - intros; reflexivity.
  - intro a.
    abstract (rewrite transport_paths_FFlr, pushout_rec_beta_pp, ap_V, pushout_rec_beta_pp; hott_simpl).
Defined.

Definition pushout_sym {A B C} {f : A -> B} {g : A -> C} : pushout f g <~> pushout g f :=
equiv_adjointify pushout_sym_map pushout_sym_map sect_pushout_sym_map sect_pushout_sym_map.

(** ** Equivalences *)

(** Pushouts preserve equivalences. *)

Lemma equiv_pushout {A B C f g A' B' C' f' g'}
  (eA : A <~> A') (eB : B <~> B') (eC : C <~> C')
  (p : eB o f == f' o eA) (q : eC o g == g' o eA)
  : pushout f g <~> pushout f' g'.
Proof.
  refine (equiv_functor_coeq' eA (equiv_functor_sum' eB eC) _ _).
  all:unfold pointwise_paths.
  all:intro; simpl; apply ap.
  + apply p.
  + apply q.
Defined.

Lemma equiv_pushout_pp {A B C f g A' B' C' f' g'}
  {eA : A <~> A'} {eB : B <~> B'} {eC : C <~> C'}
  {p : eB o f == f' o eA} {q : eC o g == g' o eA}
  : forall a : A, ap (equiv_pushout eA eB eC p q) (pp a)
    = ap push (ap inl (p a)) @ pp (eA a) @ ap push (ap inr (q a))^.
Proof.
  apply @functor_coeq_beta_cp.
Defined.

(** ** Sigmas *)

(** Pushouts commute with sigmas *)

Section EquivSigmaPushout.
  
  Context {X : Type}
          (A : X -> Type) (B : X -> Type) (C : X -> Type)
          (f : forall x, A x -> B x) (g : forall x, A x -> C x).

  Let esp1 : { x : X & pushout (f x) (g x) }
             -> pushout (functor_sigma idmap f) (functor_sigma idmap g).
  Proof.
    intros [x p].
    srefine (pushout_rec _ _ _ _ p).
    + intros b. exact (pushl (x;b)).
    + intros c. exact (pushr (x;c)).
    + intros a; cbn. exact (pp (x;a)).
  Defined.

  Let esp1_beta_pp (x : X) (a : A x)
    : ap esp1 (path_sigma' (fun x => pushout (f x) (g x)) 1 (pp a))
      = pp (x;a).
  Proof.
    rewrite (ap_path_sigma (fun x => pushout (f x) (g x))
                           (fun x a => esp1 (x;a)) 1 (pp a)); cbn.
    rewrite !concat_p1.
    unfold esp1; rewrite pushout_rec_beta_pp.
    reflexivity.
  Qed.

  Let esp2 : pushout (functor_sigma idmap f) (functor_sigma idmap g)
             -> { x : X & pushout (f x) (g x) }.
  Proof.
    srefine (pushout_rec _ _ _ _).
    + exact (functor_sigma idmap (fun x => @pushl _ _ _ (f x) (g x))).
    + exact (functor_sigma idmap (fun x => @pushr _ _ _ (f x) (g x))).
    + intros [x a]; unfold functor_sigma; cbn.
      srefine (path_sigma' _ 1 _); cbn.
      apply pp.
  Defined.

  Let esp2_beta_pp (x : X) (a : A x)
    : ap esp2 (pp (x;a)) = path_sigma' (fun x:X => pushout (f x) (g x)) 1 (pp a).
  Proof.
    unfold esp2.
    rewrite pushout_rec_beta_pp.
    reflexivity.
  Qed.

  Definition equiv_sigma_pushout
    : { x : X & pushout (f x) (g x) }
        <~> pushout (functor_sigma idmap f) (functor_sigma idmap g).
  Proof.
    srefine (equiv_adjointify esp1 esp2 _ _).
    - srefine (pushout_ind _ _ _ _); cbn.
      + reflexivity.
      + reflexivity.
      + intros [x a].
        rewrite transport_paths_FlFr.
        rewrite ap_idmap, concat_p1.
        apply moveR_Vp. rewrite concat_p1.
        rewrite ap_compose.
        rewrite esp2_beta_pp, esp1_beta_pp.
        reflexivity.
    - intros [x a]; revert a.
      srefine (pushout_ind _ _ _ _); cbn.
      + reflexivity.
      + reflexivity.
      + intros a.
        rewrite transport_paths_FlFr.
        rewrite concat_p1; apply moveR_Vp; rewrite concat_p1.
        rewrite (ap_compose (exist _ x) (esp2 o esp1)).
        rewrite (ap_compose esp1 esp2).
        rewrite (ap_existT (fun x => pushout (f x) (g x)) x _ _ (pp a)).
        rewrite esp1_beta_pp, esp2_beta_pp.
        reflexivity.
  Defined.

End EquivSigmaPushout.

(** ** Cones of hsets *)

Section SetCone.
  Context {A B : hSet} (f : A -> B).

  Definition setcone := Trunc 0 (pushout f (const tt)).

  Global Instance istrunc_setcone : IsHSet setcone := _.

  Definition setcone_point : setcone := tr (push (inr tt)).
End SetCone.
