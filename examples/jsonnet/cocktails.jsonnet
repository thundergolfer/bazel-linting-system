local martinis = import 'martinis.libsonnet';

// All single-quote strings should change to double-quote.
// This comment should not change.

{
  'Vodka Martini': martinis['Vodka Martini'],
  # This is a comment that will change when linter is run
  Manhattan: {
    ingredients: [
      { kind: 'Rye', qty: 2.5 },
      { kind: 'Sweet Red Vermouth', qty: 1 },
      { kind: 'Angostura', qty: 'dash' },
    ],
    garnish: 'Maraschino Cherry',
    served: 'Straight Up',
  },
}