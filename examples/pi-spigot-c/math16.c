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

void main() {
   int a,b,c,d,e;

   a = 234;
   b = 56;

   c = a * b;

   if (c == 13104) {
      putchar('.');
   } else {
      putchar('x');
   }

   d = a / b;

   if (d == 4) {
      putchar('.');
   } else {
      putchar('x');
   }

   e = a % b;

   if (e == 10) {
      putchar('.');
   } else {
      putchar('x');
   }

   putchar(10);
   putchar(13);

}
