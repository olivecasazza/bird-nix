# Linked list from nested Vireo pairs
let
  nil   = V false false;   # sentinel
  cons  = head: tail: V head tail;
  car   = pair: pair K;    # first element
  cdr   = pair: pair KI;   # rest of list
  myList = cons 1 (cons 2 (cons 3 nil));
in {
  first  = car myList;
  second = car (cdr myList);
  third  = car (cdr (cdr myList));
}
