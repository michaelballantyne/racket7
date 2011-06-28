#lang scribble/doc
@(require "mz.rkt")

@(define lit-ellipsis (racket ...))

@(define syntax-eval
   (lambda ()
     (let ([the-eval (make-base-eval)])
       (the-eval '(require (for-syntax racket/base)))
       the-eval)))

@title[#:tag "stx-patterns"]{Pattern-Based Syntax Matching}

@defform/subs[(syntax-case stx-expr (literal-id ...)
                clause ...)
              ([clause [pattern result-expr]
                       [pattern fender-expr result-expr]]
               [pattern _
                        id
                        (pattern ...)
                        (pattern ...+ . pattern)
                        (pattern ... pattern ellipsis pattern ...)
                        (pattern ... pattern ellipsis pattern ... . pattern)
                        (code:line #,(tt "#")(pattern ...))
                        (code:line #,(tt "#")(pattern ... pattern ellipsis pattern ...))
                        (code:line #,(tt "#s")(key-datum pattern ...))
                        (code:line #,(tt "#s")(key-datum pattern ... pattern ellipsis pattern ...))
                        (ellipsis stat-pattern)
                        const]
               [stat-pattern id
                             (stat-pattern ...)
                             (stat-pattern ...+ . stat-pattern)
                             (code:line #,(tt "#")(stat-pattern ...))
                             const]
               [ellipsis #,lit-ellipsis])]{

Finds the first @racket[pattern] that matches the syntax object
produced by @racket[stx-expr], and for which the corresponding
@racket[fender-expr] (if any) produces a true value; the result is
from the corresponding @racket[result-expr], which is in tail position
for the @racket[syntax-case] form. If no @racket[clause] matches, then
the @exnraise[exn:fail:syntax]; the exception is generated by calling
@racket[raise-syntax-error] with @racket[#f] as the ``name'' argument,
a string with a generic error message, and the result of @racket[stx-expr].

A syntax object matches a @racket[pattern] as follows:

 @specsubform[_]{

 A @racket[_] pattern (i.e., an identifier with the same binding as
 @racket[_]) matches any syntax object.}

 @specsubform[id]{

 An @racket[id] matches any syntax object when it is not bound to
 @racket[...] or @racket[_] and does not have the same binding as
 any @racket[literal-id]. The @racket[id] is further bound as
 @deftech{pattern variable} for the corresponding @racket[fender-expr]
 (if any) and @racket[result-expr]. A pattern-variable binding is a
 transformer binding; the pattern variable can be reference only
 through forms like @racket[syntax]. The binding's value is the syntax
 object that matched the pattern with a @deftech{depth marker} of
 @math{0}.

 An @racket[id] that has the same binding as a @racket[literal-id]
 matches a syntax object that is an identifier with the same binding
 in the sense of @racket[free-identifier=?].  The match does not
 introduce any @tech{pattern variables}.}

 @specsubform[(pattern ...)]{

 A @racket[(pattern ...)] pattern matches a syntax object whose datum
 form (i.e., without lexical information) is a list with as many
 elements as sub-@racket[pattern]s in the pattern, and where each
 syntax object that corresponds to an element of the list matches
 the corresponding sub-@racket[pattern].

 Any @tech{pattern variables} bound by the sub-@racket[pattern]s are
 bound by the complete pattern; the bindings must all be distinct.}

 @specsubform[(pattern ...+ . pattern)]{

 The last @racket[pattern] must not be a @racket/form[(pattern ...)],
 @racket/form[(pattern ...+ . pattern)], @racket/form[(pattern ... pattern
 ellipsis pattern ...)], or @racket/form[(pattern ... pattern ellipsis
 pattern ... . pattern)] form.

 Like the previous kind of pattern, but matches syntax objects that
 are not necessarily lists; for @math{n} sub-@racket[pattern]s before
 the last sub-@racket[pattern], the syntax object's datum must be a
 pair such that @math{n-1} @racket[cdr]s produce pairs. The last
 sub-@racket[pattern] is matched against the syntax object
 corresponding to the @math{n}th @racket[cdr] (or the
 @racket[datum->syntax] coercion of the datum using the nearest
 enclosing syntax object's lexical context and source location).}

 @specsubform[(pattern ... pattern ellipsis pattern ...)]{

 Like the @racket[(pattern ...)] kind of pattern, but matching a
 syntax object with any number (zero or more) elements that match the
 sub-@racket[pattern] followed by @racket[ellipsis] in the
 corresponding position relative to other sub-@racket[pattern]s.

 For each pattern variable bound by the sub-@racket[pattern] followed
 by @racket[ellipsis], the larger pattern binds the same pattern
 variable to a list of values, one for each element of the syntax
 object matched to the sub-@racket[pattern], with an incremented
 @tech{depth marker}. (The sub-@racket[pattern] itself may contain
 @racket[ellipsis], leading to a pattern variables bound to lists of
 lists of syntax objects with a @tech{depth marker} of @math{2}, and
 so on.)}

 @specsubform[(pattern ... pattern ellipsis pattern ... . pattern)]{

 Like the previous kind of pattern, but with a final
 sub-@racket[pattern] as for @racket[(pattern ...+ . pattern)].  The
 final @racket[pattern] never matches a syntax object whose datum is a
 pair.}

 @specsubform[(code:line #,(tt "#")(pattern ...))]{

 Like a @racket[(pattern ...)] pattern, but matching a vector syntax object
 whose elements match the corresponding sub-@racket[pattern]s.}

 @specsubform[(code:line #,(tt "#")(pattern ... pattern ellipsis pattern ...))]{

 Like a @racket[(pattern ... pattern ellipsis pattern ...)] pattern,
 but matching a vector syntax object whose elements match the
 corresponding sub-@racket[pattern]s.}

 @specsubform[(code:line #,(tt "#s")(key-datum pattern ...))]{

 Like a @racket[(pattern ...)] pattern, but matching a @tech{prefab}
 structure syntax object whose fields match the corresponding
 sub-@racket[pattern]s. The @racket[key-datum] must correspond to a
 valid first argument to @racket[make-prefab-struct].}

 @specsubform[(code:line #,(tt "#s")(key-datum pattern ... pattern ellipsis pattern ...))]{

 Like a @racket[(pattern ... pattern ellipsis pattern ...)] pattern,
 but matching a @tech{prefab} structure syntax object whose elements
 match the corresponding sub-@racket[pattern]s.}

 @specsubform[(ellipsis stat-pattern)]{

 Matches the same as @racket[stat-pattern], which is like a @racket[pattern],
 but identifiers with the binding @racket[...] are treated the same as
 other @racket[id]s.}

 @specsubform[const]{

 A @racket[const] is any datum that does not match one of the
 preceding forms; a syntax object matches a @racket[const] pattern
 when its datum is @racket[equal?] to the @racket[quote]d
 @racket[const].}

@mz-examples[
(require (for-syntax racket/base))
(define-syntax (swap stx)
  (syntax-case stx ()
    [(_ a b) #'(let ([t a])
                 (set! a b)
                 (set! b t))]))

(let ([x 5] [y 10])
  (swap x y)
  (list x y))

(syntax-case #'(ops 1 2 3 => +) (=>)
  [(_ x ... => op) #'(op x ...)])

(syntax-case #'(let ([x 5] [y 9] [z 12])
                 (+ x y z))
             (let)
  [(let ([var expr] ...) body ...)
   (list #'(var ...)
         #'(expr ...))])
]}

@defform[(syntax-case* stx-expr (literal-id ...) id-compare-expr
           clause ...)]{

Like @racket[syntax-case], but @racket[id-compare-expr] must produce a
procedure that accepts two arguments. A @racket[literal-id] in a
@racket[_pattern] matches an identifier for which the procedure 
returns true when given the identifier to match (as the first argument)
and the identifier in the @racket[_pattern] (as the second argument).

In other words, @racket[syntax-case] is like @racket[syntax-case*] with
an @racket[id-compare-expr] that produces @racket[free-identifier=?].}


@defform[(with-syntax ([pattern stx-expr] ...)
           body ...+)]{

Similar to @racket[syntax-case], in that it matches a @racket[pattern]
to a syntax object. Unlike @racket[syntax-case], all @racket[pattern]s
are matched, each to the result of a corresponding @racket[stx-expr],
and the pattern variables from all matches (which must be distinct)
are bound with a single @racket[body] sequence. The result of the
@racket[with-syntax] form is the result of the last @racket[body],
which is in tail position with respect to the @racket[with-syntax]
form.

If any @racket[pattern] fails to match the corresponding
@racket[stx-expr], the @exnraise[exn:fail:syntax].

A @racket[with-syntax] form is roughly equivalent to the following
@racket[syntax-case] form:

@racketblock[
(syntax-case (list stx-expr ...) ()
  [(pattern ...) (let () body ...+)])
]

However, if any individual @racket[stx-expr] produces a
non-@tech{syntax object}, then it is converted to one using
@racket[datum->syntax] and the lexical context and source location of
the individual @racket[stx-expr].

@examples[#:eval (syntax-eval)
(define-syntax (hello stx)
  (syntax-case stx ()
    [(_ name place)
     (with-syntax ([print-name #'(printf "~a\n" 'name)]
                   [print-place #'(printf "~a\n" 'place)])
       #'(begin
           (define (name times)
             (printf "Hello\n")
             (for ([i (in-range 0 times)])
                  print-name))
           (define (place times)
             (printf "From\n")
             (for ([i (in-range 0 times)])
                  print-place))))]))

(hello jon utah)
(jon 2)
(utah 2)

(define-syntax (math stx)
  (define (make+1 expression)
    (with-syntax ([e expression])
      #'(+ e 1)))
  (syntax-case stx ()
    [(_ numbers ...)
     (with-syntax ([(added ...)
                    (map make+1
                         (syntax->list #'(numbers ...)))])
       #'(begin
           (printf "got ~a\n" added)
           ...))]))

(math 3 1 4 1 5 9)
]}

@defform/subs[(syntax template)
              ([template id
                         (template-elem ...)
                         (template-elem ...+ . template)
                         (code:line #,(tt "#")(template-elem ...))
                         (code:line #,(tt "#s")(key-datum template-elem ...))
                         (ellipsis stat-template)
                         const]
               [template-elem (code:line template ellipsis ...)]
               [stat-template id
                              (stat-template ...)
                              (stat-template ... . stat-template)
                              (code:line #,(tt "#")(stat-template ...))
                              (code:line #,(tt "#s")(key-datum stat-template ...))
                              const]
               [ellipsis #,lit-ellipsis])]{

Constructs a syntax object based on a @racket[template], which can
include @tech{pattern variables} bound by @racket[syntax-case] or
@racket[with-syntax].

Template forms produce a syntax object as follows:

 @specsubform[id]{

 If @racket[id] is bound as a @tech{pattern variable}, then
 @racket[id] as a template produces the @tech{pattern variable}'s
 match result. Unless the @racket[id] is a sub-@racket[template] that is
 replicated by @racket[ellipsis] in a larger @racket[template], the
 @tech{pattern variable}'s value must be a syntax object with a
 @tech{depth marker} of @math{0} (as opposed to a list of
 matches).

 More generally, if the @tech{pattern variable}'s value has a depth
 marker @math{n}, then it can only appear within a template where it
 is replicated by at least @math{n} @racket[ellipsis]es. In that case,
 the template will be replicated enough times to use each match result
 at least once.

 If @racket[id] is not bound as a pattern variable, then @racket[id]
 as a template produces @racket[(quote-syntax id)].}

 @specsubform[(template-elem ...)]{

 Produces a syntax object whose datum is a list, and where the
 elements of the list correspond to syntax objects produced by the
 @racket[template-elem]s.

 A @racket[template-elem] is a sub-@racket[template] replicated by any
 number of @racket[ellipsis]es:

 @itemize[

  @item{If the sub-@racket[template] is replicated by no
   @racket[ellipsis]es, then it generates a single syntax object to
   incorporate into the result syntax object.}

  @item{If the sub-@racket[template] is replicated by one
   @racket[ellipsis], then it generates a sequence of syntax objects
   that is ``inlined'' into the resulting syntax object.

   The number of generated elements depends on the values of
   @tech{pattern variables} referenced within the
   sub-@racket[template]. There must be at least one @tech{pattern
   variable} whose value has a @tech{depth marker} less than the
   number of @racket[ellipsis]es after the pattern variable within the
   sub-@racket[template].

   If a @tech{pattern variable} is replicated by more
   @racket[ellipsis]es in a @racket[template] than the @tech{depth
   marker} of its binding, then the @tech{pattern variable}'s result
   is determined normally for inner @racket[ellipsis]es (up to the
   binding's @tech{depth marker}), and then the result is replicated
   as necessary to satisfy outer @racket[ellipsis]es.}

 @item{For each @racket[ellipsis] after the first one, the preceding
   element (with earlier replicating @racket[ellipsis]es) is
   conceptually wrapped with parentheses for generating output, and
   then the wrapping parentheses are removed in the resulting syntax
   object.}]}

 @specsubform[(template-elem ... . template)]{

  Like the previous form, but the result is not necessarily a list;
  instead, the place of the empty list in the resulting syntax object's
  datum is taken by the syntax object produced by @racket[template].}

 @specsubform[(code:line #,(tt "#")(template-elem ...))]{

   Like the @racket[(template-elem ...)] form, but producing a syntax
   object whose datum is a vector instead of a list.}

 @specsubform[(code:line #,(tt "#s")(key-datum template-elem ...))]{

   Like the @racket[(template-elem ...)] form, but producing a syntax
   object whose datum is a @tech{prefab} structure instead of a list.
   The @racket[key-datum] must correspond to a valid first argument of
   @racket[make-prefab-struct].}

 @specsubform[(ellipsis stat-template)]{

  Produces the same result as @racket[stat-template], which is like a
  @racket[template], but @racket[...] is treated like an @racket[id]
  (with no pattern binding).}

 @specsubform[const]{

  A @racket[const] template is any form that does not match the
  preceding cases, and it produces the result @racket[(quote-syntax
  const)].}

A @racket[(#,(racketkeywordfont "syntax") template)] form is normally
abbreviated as @racket[#'template]; see also
@secref["parse-quote"]. If @racket[template] contains no pattern
variables, then @racket[#'template] is equivalent to
@racket[(quote-syntax template)].}


@defform[(quasisyntax template)]{

Like @racket[syntax], but @racket[(#,(racketkeywordfont "unsyntax")
_expr)] and @racket[(#,(racketkeywordfont "unsyntax-splicing") _expr)]
escape to an expression within the @racket[template].

The @racket[_expr] must produce a syntax object (or syntax list) to be
substituted in place of the @racket[unsyntax] or
@racket[unsyntax-splicing] form within the quasiquoting template, just
like @racket[unquote] and @racket[unquote-splicing] within
@racket[quasiquote]. (If the escaped expression does not generate a
syntax object, it is converted to one in the same way as for the
right-hand side of @racket[with-syntax].)  Nested
@racket[quasisyntax]es introduce quasiquoting layers in the same way
as nested @racket[quasiquote]s.

Also analogous to @racket[quasiquote], the reader converts @litchar{#`}
to @racket[quasisyntax], @litchar{#,} to @racket[unsyntax], and
@litchar["#,@"] to @racket[unsyntax-splicing]. See also
@secref["parse-quote"].}



@defform[(unsyntax expr)]{

Illegal as an expression form. The @racket[unsyntax] form is for use
only with a @racket[quasisyntax] template.}


@defform[(unsyntax-splicing expr)]{

Illegal as an expression form. The @racket[unsyntax-splicing] form is
for use only with a @racket[quasisyntax] template.}


@defform[(syntax/loc stx-expr template)]{

Like @racket[syntax], except that the immediate resulting syntax
object takes its source-location information from the result of
@racket[stx-expr] (which must produce a syntax object), unless the
@racket[template] is just a pattern variable, or both the source and
position of @racket[stx-expr] are @racket[#f].}


@defform[(quasisyntax/loc stx-expr template)]{

Like @racket[quasisyntax], but with source-location assignment like
@racket[syntax/loc].}


@defform[(quote-syntax/prune id)]{

Like @racket[quote-syntax], but the lexical context of @racket[id] is
pruned via @racket[identifier-prune-lexical-context] to including
binding only for the symbolic name of @racket[id] and for
@racket['#%top]. Use this form to quote an identifier when its lexical
information will not be transferred to other syntax objects (except
maybe to @racket['#%top] for a top-level binding).}


@defform[(syntax-rules (literal-id ...)
           [(id . pattern) template] ...)]{

Equivalent to

@racketblock/form[
(lambda (stx)
  (syntax-case stx (literal-id ...)
    [(_generated-id . pattern) (syntax template)] ...))
]

where each @racket[_generated-id] binds no identifier in the
corresponding @racket[template].}


@defform[(syntax-id-rules (literal-id ...)
           [pattern template] ...)]{

Equivalent to

@racketblock[
(lambda (stx)
  (make-set!-transformer
   (syntax-case stx (literal-id ...)
     [pattern (syntax template)] ...)))
]}


@defform[(define-syntax-rule (id . pattern) template)]{

Equivalent to

@racketblock/form[
(define-syntax id
  (syntax-rules ()
   [(id . pattern) template]))
]

but with syntax errors potentially phrased in terms of 
@racket[pattern].}


@defidform[...]{

The @racket[...] transformer binding prohibits @racket[...] from
being used as an expression. This binding is useful only in syntax
patterns and templates, where it indicates repetitions of a pattern or
template. See @racket[syntax-case] and @racket[syntax].}

@defidform[_]{

The @racket[_] transformer binding prohibits @racket[_] from being
used as an expression. This binding is useful only in syntax patterns,
where it indicates a pattern that matches any syntax object. See
@racket[syntax-case].}


@defproc[(syntax-pattern-variable? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a value that, as a
transformer-binding value, makes the bound variable as pattern
variable in @racket[syntax] and other forms. To check whether an
identifier is a pattern variable, use @racket[syntax-local-value] to
get the identifier's transformer value, and then test the value with
@racket[syntax-pattern-variable?].

The @racket[syntax-pattern-variable?] procedure is provided
@racket[for-syntax] by @racketmodname[racket/base].}
