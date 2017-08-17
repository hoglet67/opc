#define SCALE 10000

void init() {
   asm  {
      ORG 0x100
      mov  r15, r0, _main
   };
}

void putchar(char c) {
   asm __leafs {
      ld  r1, r14, 1
      jsr r13, r0, 0xffee
   };
}

void decimal_out(long i) {
   long d = SCALE / 10;
   while (d) {
      long c = (i / d); 
      putchar((char)(48 + c % 10));
      d /= 10;
   }
}

void main() {
   decimal_out(12345L);
}
