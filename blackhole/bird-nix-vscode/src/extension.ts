import * as vscode from 'vscode';

const birdDocs: Record<string, { signature: string; description: string; type: string }> = {
  'I': { signature: 'I x = x', description: 'Identity Bird: Always returns its argument unchanged.', type: 'a -> a' },
  'M': { signature: 'M x = x x', description: 'Mockingbird: Makes a bird hear itself. Self-application.', type: '(a -> a) -> a' },
  'K': { signature: 'K x y = x', description: 'Kestrel: Always returns the first argument, ignoring the second.', type: 'a -> b -> a' },
  'KI': { signature: 'KI x y = y', description: 'Kite: Always returns the second argument, ignoring the first.', type: 'a -> b -> b' },
  'B': { signature: 'B f g x = f (g x)', description: 'Bluebird: Function composition. Composes two functions.', type: '(b -> c) -> (a -> b) -> a -> c' },
  'W': { signature: 'W f x = f x x', description: 'Warbler: Duplicates the argument. Feeds the same value twice.', type: '(a -> a -> b) -> a -> b' },
  'S': { signature: 'S f g x = f x (g x)', description: 'Starling: Distributes application. S K K = I.', type: '(a -> b -> c) -> (a -> b) -> a -> c' },
  'L': { signature: 'L x y = x (y x)', description: 'Lark: Self-application helper. Makes others listen to themselves.', type: '(a -> b) -> (a -> a) -> b' },
  'Y': { signature: 'Y f = f (Y f)', description: 'Sage Bird: Fixed-point combinator. Enables recursion.', type: '(a -> a) -> a' },
};

export function activate(context: vscode.ExtensionContext) {
  console.log('Bird-Nix extension activated');

  const hoverProvider = vscode.languages.registerHoverProvider('bird-nix', {
    provideHover(document, position) {
      const wordRange = document.getWordRangeAtPosition(position, /[A-Z][A-Z]?/);
      if (!wordRange) return null;
      const word = document.getText(wordRange);
      const info = birdDocs[word];
      if (!info) return null;
      const md = new vscode.MarkdownString();
      md.appendCodeblock(info.signature, 'nix');
      md.appendMarkdown(`\n\n${info.description}\n\n**Type:** \`${info.type}\``);
      return new vscode.Hover(md);
    },
  });

  context.subscriptions.push(hoverProvider);
}

export function deactivate() {}
