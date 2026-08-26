# Postplan Components

Use these components as the standard vocabulary for generated plans. Keep the
markup and class names exact so local plan HTML, hosted pages, and future
automation can recognize the structure.

## Page Shell

Generated plans use a standalone document with this body shape. postplan.dev
serves the uploaded file byte-for-byte with no injected chrome, so the local
file and the hosted page render identically — whatever the document does not
provide, the hosted page will not have either.

```html
<main class="pp-plan">
  <header class="pp-hero">...</header>
  <div class="pp-plan-shell">
    <aside class="pp-toc" aria-label="Plan contents">...</aside>
    <div class="pp-plan-content">...</div>
  </div>
</main>
```

## Section Navigation

Use for plans with three or more sections. Keep links and section IDs in the
same order. Include the marker element; the standard script moves it as the
reader scrolls.

```html
<aside class="pp-toc" aria-label="Plan contents">
  <p class="pp-toc__label">contents</p>
  <nav>
    <span class="pp-toc__marker" aria-hidden="true"></span>
    <a href="#context">Context</a>
    <a href="#recommendation">Recommendation</a>
    <a href="#implementation">Implementation</a>
  </nav>
</aside>
```

## Callouts

Variants are `note`, `decision`, `risk`, and `success`.

```html
<div class="pp-callout decision">
  <div class="pp-callout__label">Recommendation</div>
  <p>Proceed with the smaller migration first, then expand after verification.</p>
</div>
```

## Stats

Use stats for a small set of comparable values. Do not use them for decorative
numbers.

```html
<section class="pp-stats" aria-label="Plan metrics">
  <div class="pp-stat">
    <div class="pp-stat__label">Risk</div>
    <div class="pp-stat__value">medium</div>
    <div class="pp-stat__note">One external dependency</div>
  </div>
</section>
```

## Badges

Variants are `success`, `warning`, `danger`, `accent`, and `plain`.

```html
<span class="pp-badge success">ready</span>
<span class="pp-badge warning">watch</span>
<span class="pp-badge danger">blocked</span>
```

## Facts

Use facts for concise metadata that should remain visible near the relevant
section.

```html
<dl class="pp-facts">
  <dt>Owner</dt><dd>platform</dd>
  <dt>Scope</dt><dd>CLI, publish API, hosted renderer</dd>
</dl>
```

## Tables

Use captions and header scopes. Wrap wide tables in `.pp-table-wrap`; add
`class="num"` to numeric cells.

```html
<div class="pp-table-wrap" role="region" aria-label="Option comparison" tabindex="0">
  <table>
    <caption>Option comparison</caption>
    <thead>
      <tr>
        <th scope="col">Option</th>
        <th scope="col">Tradeoff</th>
        <th scope="col" class="num">Effort</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <th scope="row">A</th>
        <td>Lowest change surface</td>
        <td class="num">2 days</td>
      </tr>
    </tbody>
  </table>
</div>
```

## Code Blocks

Use fenced-style `pre > code` blocks. Add a language class when known; the
standard script syntax-highlights code blocks automatically.

```html
<pre><code class="language-ts">const result = await publishPlan(input);</code></pre>
```

## Interactive Controls

When a plan includes scoring, ranking, sliders, filters, or what-if assumptions,
put controls in a `.pp-tool` section and include an export action.

```html
<section class="pp-tool" aria-labelledby="assumptions-heading">
  <h2 id="assumptions-heading">Assumptions</h2>
  <label>Migration risk <input type="range" min="1" max="5" value="3"></label>
  <button type="button">Copy assumptions</button>
</section>
```
