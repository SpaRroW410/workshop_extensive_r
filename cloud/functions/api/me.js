// GET /api/me — who is signed in, which products they hold, and which track sites they can open.
// Signed out: { user: null, products: [], open: { basic: true, ... } }.
import { currentUser, productsOf, json } from '../../src/auth.js';
import { TRACKS, trackProduct, holds, PRODUCTS } from '../../src/products.js';

export async function onRequestGet({ request, env }) {
  const user = await currentUser(request, env);
  const products = user ? await productsOf(env, user.id) : [];
  const open = Object.fromEntries(TRACKS.map((t) => [t, holds(products, trackProduct(t))]));
  const tracks = Object.fromEntries(TRACKS.map((t) => [t, trackProduct(t)]));
  if (!user) return json({ user: null, products, open, tracks, catalog: PRODUCTS });
  return json({
    user: { id: user.id, name: user.name, email: user.email, image: user.image || null },
    products,
    open,
    tracks,
    catalog: PRODUCTS,
  });
}
