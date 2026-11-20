// Every Better Auth endpoint: /api/auth/sign-in/social, /api/auth/callback/google, /api/auth/sign-out, ...
import { getAuth } from '../../../src/auth.js';

export const onRequest = ({ request, env }) => getAuth(env).handler(request);
