Require Import Basics.Overture Basics.Equivalences Cubical.DPath
  Cubical.PathSquare Cubical.DPathSquare Cubical.PathCube Cubical.DPathCube.

(** In this file we define the Torus as a HIT generated by two loops and a square between them. *)

Notation hr := (sq_refl_h _).
Notation vr := (sq_refl_v _).

Module Export Torus.

  Private Inductive Torus :=
    | tbase.

  Axiom loop_a : tbase = tbase.
  Axiom loop_b : tbase = tbase.
  Axiom surf : PathSquare loop_a loop_a loop_b loop_b.

  (** We define the induction principle for Torus *)
  Definition Torus_ind (P : Torus -> Type) (pb : P tbase)
    (pla : DPath P loop_a pb pb) (plb : DPath P loop_b pb pb)
    (ps : DPathSquare P surf pla pla plb plb) (x : Torus) : P x
  := (match x with tbase => fun _ _ _ => pb end) pla plb ps.

  (** We declare propositional computational rules for loop_a and loop_b *)
  Axiom Torus_ind_beta_loop_a : forall (P : Torus -> Type) (pb : P tbase)
    (pla : DPath P loop_a pb pb) (plb : DPath P loop_b pb pb)
    (ps : DPathSquare P surf pla pla plb plb), DPathSquare P hr
      (apD (Torus_ind P pb pla plb ps) (loop_a)) pla 1%dpath 1%dpath.

  Axiom Torus_ind_beta_loop_b : forall (P : Torus -> Type) (pb : P tbase)
    (pla : DPath P loop_a pb pb) (plb : DPath P loop_b pb pb)
    (ps : DPathSquare P surf pla pla plb plb), DPathSquare P hr
      (apD (Torus_ind P pb pla plb ps) (loop_b)) plb 1%dpath 1%dpath.

  (** We write out the computation rule for surf even though we will not use it. Instead we currently have an unfinished recursion computation principle, but we don't currently know how to derive it from this *)
  Axiom Torus_ind_beta_surf : forall (P : Torus -> Type) (pb : P tbase)
    (pla : DPath P loop_a pb pb) (plb : DPath P loop_b pb pb)
    (ps : DPathSquare P surf pla pla plb plb),
      DPathCube P (cu_refl_lr _) (ds_apD (Torus_ind P pb pla plb ps) surf) ps
        (Torus_ind_beta_loop_a _ _ _ _ _) (Torus_ind_beta_loop_a _ _ _ _ _)
        (Torus_ind_beta_loop_b _ _ _ _ _) (Torus_ind_beta_loop_b _ _ _ _ _).

End Torus.

(** We can now define Torus recursion as a special case of Torus induction *)
Definition Torus_rec (P : Type) (pb : P) (pla plb : pb = pb)
  (ps : PathSquare pla pla plb plb) : Torus -> P
  := Torus_ind _ pb (dp_const pla) (dp_const plb) (ds_const ps).

(** We can derive the recursion computation rules for Torus_rec *)
Lemma Torus_rec_beta_loop_a (P : Type) (pb : P) (pla plb : pb = pb)
  (ps : PathSquare pla pla plb plb)
  : PathSquare (ap (Torus_rec P pb pla plb ps) loop_a) pla 1 1.
Proof.
  refine (sq_GGcc _ (eissect _ _)
    (ds_const'^-1 (Torus_ind_beta_loop_a _ _ _ _ _))).
  apply moveR_equiv_V, dp_apD_const.
Defined.

Lemma Torus_rec_beta_loop_b (P : Type) (pb : P) (pla plb : pb = pb)
  (ps : PathSquare pla pla plb plb)
  : PathSquare (ap (Torus_rec P pb pla plb ps) loop_b) plb 1 1.
Proof.
  refine (sq_GGcc _ (eissect _ _)
    (ds_const'^-1 (Torus_ind_beta_loop_b _ _ _ _ _))).
  apply moveR_equiv_V, dp_apD_const.
Defined.

(** We ought to be able to prove this from Torus_ind_beta_surf but it is currently too difficult. Therefore we will leave it as admitted where it will simply look like an axiom. *)
Definition Torus_rec_beta_surf (P : Type) (pb : P) (pla plb : pb = pb)
  (ps : PathSquare pla pla plb plb)
  :  PathCube (sq_ap (Torus_rec P pb pla plb ps) surf) ps
      (Torus_rec_beta_loop_a P pb pla plb ps)
      (Torus_rec_beta_loop_a P pb pla plb ps)
      (Torus_rec_beta_loop_b P pb pla plb ps)
      (Torus_rec_beta_loop_b P pb pla plb ps).
Proof.
Admitted.

(** The torus is pointed. *)
Instance ispointed_torus : IsPointed Torus := tbase.

(** The loops commute. *)
Definition loops_commute_torus : loop_a @ loop_b = loop_b @ loop_a
  := equiv_sq_path^-1 surf.

(* TODO:
(* We ought to be able to prove the computation rules all at the same time *)
(* This gives me the idea of writing all our computation rules as a
   "dependent filler" *)
Definition Torus_rec_beta_cube (P : Type) (pb : P) (pla plb : pb = pb)
  (ps : PathSquare pla pla plb plb)
  : { ba : PathSquare (ap (Torus_rec P pb pla plb ps) loop_a) pla 1 1 &
    { bb : PathSquare (ap (Torus_rec P pb pla plb ps) loop_b) plb 1 1 &
    PathCube (sq_ap (Torus_rec P pb pla plb ps) surf) ps ba ba bb bb}}.
Proof.
  refine (_;_;_).
  set 
    (cu_cGcccc (eissect ds_const' _)
    (dc_const'^-1 (Torus_ind_beta_surf (fun _ => P) pb
    (dp_const pla) (dp_const plb) (ds_const' (sq_GGGG (eissect _ _)^ (eissect _ _)^ (eissect _ _)^ (eissect _ _)^ ps))))).
Admitted.
*)

