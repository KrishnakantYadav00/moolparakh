// prisma/seed.ts
// No seed data — all data is posted via API during testing.
import { PrismaClient } from '@prisma/client';

const db = new PrismaClient();

async function main() {
  console.log('Seed: nothing to seed. Post data via API endpoints.');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => db.$disconnect());
