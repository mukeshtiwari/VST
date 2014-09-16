Require Import MirrorCore.Lambda.ExprCore.
Require Import floyd.proofauto.
Require Import ExtLib.Core.RelDec.
Require Import MirrorCore.TypesI.
Require Import ExtLib.Tactics.
Require Import ExtLib.Data.Fun.
Require Import progs.list_dt.

Inductive typ :=
| tyArr : typ -> typ -> typ
| tytycontext
| tyc_expr
| tyc_type
| tyenviron
| tyval
| tyshare
| tyident
| tylist : typ -> typ
| tyint
| tyZ
| tynat
| typositive
| tybool
| tycomparison
| tytc_assert
| tyint64
| tyfloat
| tyattr
| tysignedness
| tyintsize
| tyfloatsize
| tytypelist
| tyfieldlist
| tybinary_operation
| tyunary_operation
| tyN
| tyoption : typ -> typ
| typrop
| tympred
| tysum : typ -> typ -> typ
| typrod : typ -> typ -> typ
| tyunit
| tylistspec : type -> ident -> typ.

Fixpoint typD (ts : list Type) (t : typ) : Type :=
    match t with
        | tyArr a b => typD ts a -> typD ts b
        | tytycontext => tycontext
        | tyc_expr => expr
        | tyc_type => type
        | tyenviron => environ
        | tyval => val
        | tyshare => share
        | tyident => ident
        | tylist t => list (typD ts t)
        | tyint => int
        | tyZ => Z
        | tynat => nat
        | typositive => positive
        | tybool => bool
        | tycomparison => comparison
        | tytc_assert => tc_assert
        | tyint64 => int64
        | tyfloat => float
        | tyattr => attr
        | tysignedness => signedness
        | tyintsize => intsize
        | tyfloatsize  => floatsize
        | tytypelist => typelist
        | tyfieldlist => fieldlist
        | tybinary_operation => Cop.binary_operation
        | tyunary_operation => Cop.unary_operation
        | tyN => N
        | tyoption t => option (typD ts t)
        | typrop => Prop
        | tympred => mpred
        | tysum t1 t2 => sum (typD ts t1) (typD ts t2)
        | typrod t1 t2 => prod (typD ts t1) (typD ts t2)
        | tyunit => unit
        | tylistspec t i => listspec t i  
    end.

Lemma listspec_ext : forall t i (a b: listspec t i), a = b.
intros. destruct a,b.
subst. inversion list_struct_eq0.
subst. f_equal.
apply proof_irr.
apply proof_irr.
apply proof_irr.
Qed.

Definition typ_eq_dec : forall a b : typ, {a = b} + {a <> b}.
  decide equality.
  consider (eqb_ident i i0); intros;
  try rewrite eqb_ident_spec in H. auto.
  destruct (eqb_ident_spec i i0). right. intro. intuition. subst.
  congruence.
  consider (eqb_type t t0); intros.
  rewrite eqb_type_spec in H. auto.
  destruct (eqb_type_spec t t0).
  right; intuition; subst; congruence.
 Defined.

Instance RelDec_eq_typ : RelDec (@eq typ) :=
{ rel_dec := fun a b =>
               match typ_eq_dec a b with
                 | left _ => true
                 | right _ => false
               end }.

Instance RelDec_Correct_eq_typ : RelDec_Correct RelDec_eq_typ.
Proof.
  constructor.
  intros.
  unfold rel_dec; simpl.
  destruct (typ_eq_dec x y); intuition.
Qed.

Inductive tyAcc' : typ -> typ -> Prop :=
| tyArrL : forall a b, tyAcc' a (tyArr a b)
| tyArrR : forall a b, tyAcc' b (tyArr a b).

Instance RType_typ : RType typ :=
{ typD := typD
; tyAcc := tyAcc'
; type_cast := fun _ a b => match typ_eq_dec a b with
                              | left pf => Some pf
                              | _ => None
                            end
}.

Instance RTypeOk_typ : @RTypeOk typ _.
Proof.
  eapply makeRTypeOk.
  { red.
    induction a; constructor; inversion 1.
    subst; auto.
    subst; auto. }
  { unfold type_cast; simpl.
    intros. destruct (typ_eq_dec x x).
    f_equal. compute.
    uip_all. reflexivity. congruence. }
  { unfold type_cast; simpl.
    intros. destruct (typ_eq_dec x y); try congruence. }
Qed.

Instance Typ2_tyArr : Typ2 _ Fun :=
{ typ2 := tyArr
; typ2_cast := fun _ _ _ => eq_refl
; typ2_match :=
    fun T ts t tr =>
      match t as t return T (TypesI.typD ts t) -> T (TypesI.typD ts t) with
        | tyArr a b => fun _ => tr a b
        | _ => fun fa => fa
      end
}.

Instance Typ2Ok_tyArr : Typ2Ok Typ2_tyArr.
Proof.
  constructor.
  { reflexivity. }
  { apply tyArrL. }
  { intros; apply tyArrR. }
  { inversion 1; subst; unfold Rty; auto. }
  { destruct x; simpl; eauto.
    left; do 2 eexists; exists eq_refl. reflexivity. }
  { destruct pf. reflexivity. }
Qed.

Instance Typ0_tyProp : Typ0 _ Prop :=
{| typ0 := typrop
 ; typ0_cast := fun _ => eq_refl
 ; typ0_match := fun T ts t =>
                   match t as t
                         return T Prop -> T (TypesI.typD ts t) -> T (TypesI.typD ts t)
                   with
                     | typrop => fun tr _ => tr
                     | _ => fun _ fa => fa
                   end
 |}.

Inductive const :=
| N : nat -> const
| Z : Z -> const
| Pos : positive -> const
| Ctype : type -> const
| Cexpr : expr -> const
| Comparison : comparison -> const.

Definition typeof_const (c : const) : typ :=
 match c with
| N _ => tynat
| Z _ => tyZ
| Pos _ => typositive
| Ctype _ => tyc_type
| Cexpr _ => tyc_expr
| Comparison _ => tycomparison
end.

Definition constD (ts : list Type) (c : const)
: typD ts (typeof_const c) :=
match c with
| N c | Z c | Pos c | Ctype c | Cexpr c | Comparison c
                                          => c
end.

Require Import ExtLib.Data.Positive.
Require Import ExtLib.Data.Z.

(*Instance RelDec_type_eq : RelDec (@eq type) :=
{ rel_dec := eqb_type }.

Instance RelDec_const_eq : RelDec (@eq const) :=
{ rel_dec := fun (a b : const) =>
               match a , b with
| N c1,  N c2 | Z c1,  Z c2 | Pos c1,  Pos c2 | Ctype c1,  Ctype c2
| Cexpr c1,  Cexpr c2 | Comparison c1,  Comparison c2 => c1 ?[ eq ] c2
| _, _ => false
end}. Set Printing All.*)



Inductive z_op :=
| fZ_lt
| fZ_le
| fZ_gt
| fZ_ge
| fZ_add
| fZ_sub
| fZ_mul
| fZ_div
| fZ_mod
| fZ_max
| fZ_opp.

Definition typeof_z_op z : typ :=
match z with
| fZ_lt
| fZ_le
| fZ_gt
| fZ_ge => (tyArr tyZ (tyArr tyZ typrop))
| fZ_add
| fZ_sub
| fZ_mul
| fZ_div
| fZ_mod
| fZ_max => (tyArr tyZ (tyArr tyZ tyZ))
| fZ_opp => (tyArr tyZ tyZ)
end.

Definition z_opD (ts : list Type) (z : z_op) : typD ts (typeof_z_op z) :=
match z with
| fZ_lt => Z.lt
| fZ_le => Z.le
| fZ_gt => Z.gt
| fZ_ge => Z.ge
| fZ_add => Z.add
| fZ_sub => Z.sub
| fZ_mul => Z.mul
| fZ_div => Z.div
| fZ_mod => Zmod
| fZ_max => Z.max
| fZ_opp => Z.opp
end.

(*Instance RelDec_func_eq : RelDec (@eq func) :=
{ rel_dec := fun (a b : func) =>
               match a , b with
                 | Plus , Plus => true*)

Inductive int_op :=
| fint_add
| fint_lt
| fint_ltu
| fint_mul
| fint_neg
| fint_sub
| fint_cmp
| fint_cmpu
| fint_repr
| fint_signed
| fint_unsigned
| fint_max_unsigned
| fint64_repr.

Definition typeof_int_op i : typ :=
match i with
| fint_lt
| fint_ltu => tyArr tyint (tyArr tyint tybool)
| fint_mul
| fint_sub
| fint_add => tyArr tyint (tyArr tyint tyint)
| fint_neg => tyArr tyint tyint
| fint_cmp
| fint_cmpu => tyArr tycomparison (tyArr tyint (tyArr tyint tybool))
| fint_repr => tyArr tyZ tyint
| fint_signed
| fint_unsigned  => tyArr tyint tyZ
| fint_max_unsigned => tyZ
| fint64_repr => tyArr tyZ tyint64
end.

Definition int_opD (ts : list Type) (i : int_op): typD ts (typeof_int_op i) :=
match i with
| fint_add => Int.add
| fint_lt => Int.lt
| fint_ltu => Int.ltu
| fint_mul => Int.mul
| fint_neg => Int.neg
| fint_sub => Int.sub
| fint_cmp => Int.cmp
| fint_cmpu => Int.cmpu
| fint_repr => Int.repr
| fint_signed => Int.signed
| fint_unsigned => Int.unsigned
| fint_max_unsigned => Int.max_unsigned
| fint64_repr => Int64.repr
end.


Inductive values :=
| fVint
| fVfloat
| fVlong
| fVptr
| fVundef.

Definition typeof_value (v : values) :=
match v with
| fVint => tyArr tyint tyval
| fVfloat => tyArr tyfloat tyval
| fVlong => tyArr tyint64 tyval
| fVptr => tyArr typositive (tyArr tyint tyval)
| fVundef => tyval
end.

Definition valueD (ts : list Type) (v : values): typD ts (typeof_value v) :=
match v with
| fVint => Vint
| fVfloat => Vfloat
| fVlong => Vlong
| fVptr => Vptr
| fVundef => Vundef
end.


Inductive eval :=
| feval_cast
| fderef_noload
| feval_field
| feval_binop
| feval_unop
| feval_id.

Check expr.eval_id.

Definition typeof_eval (e : eval) :=
 match e with
| feval_cast => tyArr tyc_type (tyArr tyc_type (tyArr tyval tyval))
| fderef_noload => tyArr tyc_type (tyArr tyval tyval)
| feval_field => tyArr tyc_type (tyArr tyident (tyArr tyval tyval))
| feval_binop => tyArr tybinary_operation (tyArr tyc_type (tyArr tyc_type (tyArr tyval (tyArr tyval tyval))))
| feval_unop => tyArr tyunary_operation (tyArr tyc_type (tyArr tyval tyval))
| feval_id => tyArr tyident (tyArr tyenviron tyval)
end.

Definition evalD (ts : list Type) (e : eval) : typD ts (typeof_eval e) :=
match e with
| feval_id => eval_id
| feval_cast => eval_cast
| fderef_noload => deref_noload
| feval_field => eval_field
| feval_binop => eval_binop
| feval_unop => eval_unop
end.


(*TODO: classify these better*)
Inductive other :=
| ftwo_power_nat
| fforce_ptr
| fand
| falign
| fmap : typ -> typ -> other
| ftyped_true
.


Definition typeof_other (o : other) :=
match o with
| ftwo_power_nat => tyArr tynat tyZ
| fforce_ptr  => tyArr tyval tyval
| fand => tyArr typrop (tyArr typrop typrop)
| falign => tyArr tyZ (tyArr tyZ tyZ)
| fmap a b => tyArr (tyArr a b) (tyArr (tylist a) (tylist b))
| ftyped_true => tyArr tyc_type (tyArr tyval typrop)
end.

Definition otherD (ts : list Type) (o : other) : typD ts (typeof_other o) :=
match o with
| ftwo_power_nat => two_power_nat
| fforce_ptr => force_ptr
| fand => and
| falign => align
| fmap t1 t2 => @map (typD ts t1) (typD ts t2)
| ftyped_true => typed_true
end.

Inductive sep :=
| fstar
| fandp
| forp
| flocal
| fprop
| fderives
| femp
| fdata_at : type -> sep
| ffield_at : type -> list ident -> sep
| flseg : forall (t: type) (i : ident), listspec t i -> sep
. 


Fixpoint reptyp (ty: type) : typ :=
  match ty with
  | Tvoid => tyunit
  | Tint _ _ _ => tyval
  | Tlong _ _ => tyval
  | Tfloat _ _ => tyval
  | Tpointer t1 a => tyval
  | Tarray t1 sz a => tylist (reptyp t1)
  | Tfunction t1 t2 _ => tyunit
  | Tstruct id fld a => reptyp_structlist fld
  | Tunion id fld a => reptyp_unionlist fld
  | Tcomp_ptr id a => tyval
  end
with reptyp_structlist (fld: fieldlist) : typ :=
  match fld with
  | Fnil => tyunit
  | Fcons id ty fld' => 
    if is_Fnil fld' 
      then reptyp ty
      else typrod (reptyp ty) (reptyp_structlist fld')
  end
with reptyp_unionlist (fld: fieldlist) : typ :=
  match fld with
  | Fnil => tyunit
  | Fcons id ty fld' => 
    if is_Fnil fld' 
      then reptyp ty
      else tysum (reptyp ty) (reptyp_unionlist fld')
  end.

Definition typeof_sep (s : sep) : typ :=
match s with
| fdata_at t => tyArr tyshare (tyArr (reptyp t) (tyArr tyval tympred))
| ffield_at t ids => tyArr tyshare (tyArr (reptyp (nested_field_type2 t ids)) (tyArr tyval tympred))
| flseg t i l => tyArr tyshare (tyArr (tylist (reptyp_structlist (@all_but_link i (list_fields)))) 
                                      (tyArr tyval (tyArr tyval tympred)))
| fstar 
| fandp
| forp => tyArr tympred (tyArr tympred tympred)
| flocal => tyArr (tyArr tyenviron typrop) (tyArr tyenviron tympred) 
| fprop => tyArr typrop tympred
| fderives => tyArr tympred (tyArr tympred typrop)
| femp => tympred
end.

Fixpoint reptyp_reptype (ts : list Type) ty {struct ty} : typD ts (reptyp ty) -> reptype ty :=
  match ty as ty0 return (typD ts (reptyp ty0) -> reptype ty0) with
    | Tvoid => fun x : unit => x
    | Tint i s a => fun x : val => x
    | Tlong s a => fun x : val => x
    | Tfloat f a => fun x : val => x
    | Tpointer t a => fun x : val => x
    | Tarray t z a => map (reptyp_reptype ts t)
    | Tfunction t t0 c => fun x : unit => x
    | Tstruct i f a => reptyp_structlist_reptype ts f
    | Tunion i f a => reptyp_unionlist_reptype ts f
    | Tcomp_ptr i a => fun x : val => x
  end
with reptyp_structlist_reptype (ts : list Type) fl {struct fl} : typD ts (reptyp_structlist fl) -> reptype_structlist fl :=
  match
    fl as fl0
    return (typD ts (reptyp_structlist fl0) -> reptype_structlist fl0)
  with
    | Fnil => fun x : typD ts (reptyp_structlist Fnil) => x
    | Fcons i t fl0 =>
      let b := is_Fnil fl0 in
      if b as b0
         return
         (typD ts
               (if b0
                then reptyp t
                else typrod (reptyp t) (reptyp_structlist fl0)) ->
          if b0
          then reptype t
          else (reptype t * reptype_structlist fl0)%type)
      then reptyp_reptype ts t
      else
        fun x : typD ts (reptyp t) * typD ts (reptyp_structlist fl0) =>
          (reptyp_reptype ts t (fst x),
           reptyp_structlist_reptype ts fl0 (snd x))
  end
with reptyp_unionlist_reptype (ts : list Type) fl {struct fl} : typD ts (reptyp_unionlist fl) -> reptype_unionlist fl :=
match
     fl as fl0
     return (typD ts (reptyp_unionlist fl0) -> reptype_unionlist fl0)
   with
   | Fnil => fun x : typD ts (reptyp_unionlist Fnil) => x
   | Fcons i t fl0 =>
       let b := is_Fnil fl0 in
       if b as b0
        return
          (typD ts
             (if b0
              then reptyp t
              else tysum (reptyp t) (reptyp_unionlist fl0)) ->
           if b0 then reptype t else (reptype t + reptype_unionlist fl0)%type)
       then reptyp_reptype ts t
       else
        fun x : typD ts (reptyp t) + typD ts (reptyp_unionlist fl0) =>
        match x with
        | inl y => inl (reptyp_reptype ts t y)
        | inr y => inr (reptyp_unionlist_reptype ts fl0 y)
        end
   end.

Definition sepD (ts : list Type) (s : sep) : typD ts (typeof_sep s).
refine
match s with
| fstar => sepcon
| fandp => andp
| forp => orp
| flocal => local
| fprop => prop
| fderives => derives
| femp => emp
| fdata_at ty => _ (* fun sh (t : reptype ty) v => data_at sh ty t v *)
| ffield_at t ids => _
| flseg t id ls => _
end. 
{ simpl. intros sh rt v.
  exact (data_at sh ty (reptyp_reptype ts _ rt) v). }
{ simpl. intros sh ty v.
  exact (field_at sh t ids (reptyp_reptype ts _ ty) v). }
{ simpl.
  intros sh lf v1 v2.
  exact (@lseg t id ls sh (List.map (reptyp_structlist_reptype ts _) lf) v1 v2). }
Defined.


Inductive func :=
| Const : const -> func
| Zop : z_op -> func
| Intop : int_op -> func
| Value : values -> func
| Eval_f : eval -> func
| Other : other -> func
| Sep : sep -> func.

Definition typeof_func (f: func) : typ :=
match f with
| Const c => typeof_const c
| Zop z => typeof_z_op z
| Intop i => typeof_int_op i
| Value v => typeof_value v
| Eval_f e => typeof_eval e
| Other o => typeof_other o
| Sep s => typeof_sep s
end.

Definition funcD (ts : list Type) (f : func) : typD ts (typeof_func f) :=
match f with
| Const c => constD ts c
| Zop z => z_opD ts z
| Intop i => int_opD ts i
| Value v => valueD ts v
| Eval_f e => evalD ts e
| Other o => otherD ts o
| Sep s => sepD ts s
end.

 