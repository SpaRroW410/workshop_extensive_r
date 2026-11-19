// GET /api/me — who is signed in and which products they hold. Signed out: { user: null, products: [] }.
import { currentUser, productsOf, json } from '../../src/auth.js';

export async function onRequestGet({ request, env }) {
  const user = await currentUser(request, env);
  if (!user) return json({ user: null, products: [] });
  return json({
    user: { id: user.id, name: user.name, email: user.email, image: user.image || null },
    products: await productsOf(env, user.id),
  });
}
