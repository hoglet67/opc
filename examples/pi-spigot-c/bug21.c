#define SCALE 10000L

void putchar(char c) {
   asm __leafs {
      ld  r1, r14, 1
      jsr r13, r0, 0xffee
   };
}

void bug21(long i) {
   long d = SCALE / 10L;
   while (d) {
      long c = (i / d); 
      putchar(48 + c % 10);
      d /= 10L;
   }
}
