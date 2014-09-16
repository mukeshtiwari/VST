Require Import floyd.proofauto.
Import ListNotations.
Require sha.sha.
Require sha.SHA256.
Local Open Scope logic.

Require Import sha.spec_sha.
Require Import sha_lemmas.
Require Import sha.HMAC_functional_prog.

Require Import sha.hmac091c.

Require Import sha.spec_hmac.

Lemma isptrD v: isptr v -> exists b ofs, v = Vptr b ofs.
Proof. intros. destruct v; try contradiction. exists b, i; trivial. Qed.

Lemma body_hmac_sha256: semax_body Vprog Gtot 
       f_HMAC HMAC_Simple_spec.
Proof.
start_function.
name key' _key.
name keylen' _key_len.
name d' _d.
name n' _n.
name md' _md.
simpl_stackframe_of.
destruct KeyStruct as [k [kl key]].
destruct DataStruct as [d [dl data]]. simpl in *.
rename H into WrshMD. 
rewrite memory_block_isptr. normalize.
rename H into isPtrMD. rename H0 into KL. rename H1 into DL. 
remember (
EX c:_,
PROP  (isptr c)
   LOCAL  (`(eq md) (eval_id _md); `(eq k) (eval_id _key);
   `(eq (Vint (Int.repr kl))) (eval_id _key_len); `(eq d) (eval_id _d);
   `(eq (Vint (Int.repr dl))) (eval_id _n);
   `(eq c) (eval_var _c t_struct_hmac_ctx_st);
   `(eq KV) (eval_var sha._K256 (tarray tuint 64)))
   SEP 
   (`(data_at_ Tsh t_struct_hmac_ctx_st c);
   `(data_block Tsh key k); `(data_block Tsh data d); `(K_vector KV);
   `(memory_block shmd (Int.repr 32) md))) as POSTCOND.
forward_if POSTCOND.
  normalize. forward.
  simpl; intros rho. entailer.
    apply isptrD in isPtrMD. destruct isPtrMD as [b [i HH]]; rewrite HH in *.
    simpl in *. inversion H0.
  simpl in *. apply isptrD in isPtrMD. destruct isPtrMD as [b [i HH]]; subst. 
   intros rho. 
   entailer.
   
  forward. subst POSTCOND. simpl. intros rho. entailer.
   rewrite data_at__isptr. normalize.
   apply exp_right with (x:=eval_var _c t_struct_hmac_ctx_st rho).
   entailer.

subst POSTCOND.
apply extract_exists_pre. intros c. normalize. rename H into isPtrC.
eapply semax_seq'. 
frame_SEP 0 1.
remember (c, k, kl, key) as WITNESS.
forward_call WITNESS.
  assert (FR: Frame =nil).
       subst Frame. reflexivity.
     rewrite FR. clear FR Frame. 
  subst WITNESS. entailer.
after_call.
subst WITNESS. normalize. simpl. rewrite elim_globals_only'. normalize.
intros h0. normalize. rename H into HmacInit.

eapply semax_seq'. 
frame_SEP 0 2 3.
remember (h0, c, d, dl, data, KV) as WITNESS.
(*Remark on confusing error messages: if the spec of HMAC_update includes _len OF tuint
  instead of _len OF tint, the following forward_call fails, complaining that
  WITNESS is not of type hmacabs * val * val * Z * list Z * val. But it is, 
  and the error message is wrong.*)
forward_call WITNESS.
  assert (FR: Frame =nil).
       subst Frame. reflexivity.
     rewrite FR. clear FR Frame. 
  subst WITNESS. entailer.
  apply andp_right. 
    admit. (*need "AxiomK" from HMAC_proof*)
    cancel. 
after_call.
subst WITNESS. normalize.
unfold update_tycon. simpl. normalize.

(**** It's not quite clear to me why we need to use semax_pre here - 
  ie why normalize can't figure this out (at least partially).
  It seems exp doesn't distribute over liftx, but it should *)
eapply semax_pre with (P':=EX  x : hmacabs, 
   PROP  ()
   LOCAL  (tc_environ Delta; tc_environ Delta; `(eq md) (eval_id _md);
   `(eq k) (eval_id _key); `(eq (Vint (Int.repr kl))) (eval_id _key_len);
   `(eq d) (eval_id _d); `(eq (Vint (Int.repr dl))) (eval_id _n);
   `(eq c) (eval_var _c t_struct_hmac_ctx_st);
   `(eq KV) (eval_var sha._K256 (tarray tuint 64)))
   SEP (`(fun a : environ =>(PROP  (hmacUpdate (firstn (Z.to_nat dl) data) dl h0 x)
       LOCAL ()
       SEP  (`(K_vector KV); `(hmacstate_ x c); `(data_block Tsh data d))) a)
      globals_only; `(data_block Tsh key k); `(memory_block shmd (Int.repr 32) md))).
  entailer. rename x into h1. apply exp_right with (x:=h1).
  entailer.
apply extract_exists_pre. intros h1. normalize. simpl. normalize.
(********************************************************)

rename H into HmacUpdate.
eapply semax_seq'. 
frame_SEP 0 1 4.
remember (h1, c, md, shmd, KV) as WITNESS.
forward_call WITNESS.
  assert (FR: Frame =nil).
       subst Frame. reflexivity.
     rewrite FR. clear FR Frame. 
  subst WITNESS. entailer.
  apply andp_right. 
    admit.  (*need "AxiomK" from HMAC_proof*)
    cancel. 
after_call.
subst WITNESS. normalize.
unfold update_tycon. simpl. normalize.

(**** Again, distribute EX over lift*)
eapply semax_pre with (P':=EX  x : list Z,
      (EX  x0 : hmacabs,
   (PROP  ()
   LOCAL  (tc_environ Delta; tc_environ Delta; tc_environ Delta;
   `(eq md) (eval_id _md); `(eq k) (eval_id _key);
   `(eq (Vint (Int.repr kl))) (eval_id _key_len); `(eq d) (eval_id _d);
   `(eq (Vint (Int.repr dl))) (eval_id _n);
   `(eq c) (eval_var _c t_struct_hmac_ctx_st);
   `(eq KV) (eval_var sha._K256 (tarray tuint 64)))
   SEP 
   (`(fun a : environ =>
     (PROP (hmacFinalSimple h1 x)
        LOCAL ()
        SEP  (`(K_vector KV); `(hmacstate_ x0 c); `(data_block shmd x md))) a) globals_only; 
      `(data_block Tsh data d); `(data_block Tsh key k))))).
  entailer. rename x into dig. apply exp_right with (x:=dig).
  rename x0 into h2. apply exp_right with (x:=h2).
  entailer.
apply extract_exists_pre. intros dig.
apply extract_exists_pre. intros h2. normalize. simpl. normalize.
(********************************************************)

rename H into HmacFinalSimple.
eapply semax_seq'. 
frame_SEP 1.
remember (h2,c) as WITNESS.
forward_call WITNESS.
  assert (FR: Frame =nil).
       subst Frame. reflexivity.
     rewrite FR. clear FR Frame. 
  subst WITNESS. entailer.
after_call.
subst WITNESS. normalize.
unfold update_tycon. simpl. normalize. simpl.

forward.
apply exp_right with (x:=dig).
simpl_stackframe_of. normalize. clear H0. 
assert (HS: hmacSimple key kl data dl dig).
    exists h0, h1. 
    split. destruct KL as [KL1 [KLb KLc]].
           rewrite KL1. assumption.
    split. destruct DL as [DL1 [DLb DLc]]. rewrite DL1 in *; clear DL1. 
           assert (FF: firstn (Z.to_nat (Zlength data)) data = data). 
             apply firstn_same. rewrite Zlength_correct, Nat2Z.id. omega. 
           rewrite FF in *. assumption. 
    assumption.
assert (Size: sizeof t_struct_hmac_ctx_st <= Int.max_unsigned).
  rewrite int_max_unsigned_eq; simpl. omega.
entailer. clear H0. cancel. 
  unfold data_block. 
  rewrite Zlength_correct; simpl. 
  rewrite <- memory_block_data_at_; try reflexivity. 
  entailer. clear H0.
  apply andp_right. 
     rewrite (split_array_at 0). rewrite array_at_emp. entailer.
     apply isptrD in isPtrC. destruct isPtrC as [b [i Bi]].
          rewrite Bi in *. unfold align_compatible in *. simpl in *. admit. (*ADMIT3: aligment*)
  omega. 
  rewrite memory_block_array_tuchar. cancel. simpl. omega.
Qed.