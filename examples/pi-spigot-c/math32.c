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
   long a,b,c,d,e;

   a = 123456;
   b = 1234;

   c = a * b;

   if (c == 0x9149880) {
      putchar('.');
   } else {
      putchar('x');
   }

//   d = a / b;

//   e = a % b;

   putchar(10);
   putchar(13);

}
