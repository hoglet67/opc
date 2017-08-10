void init() {
   asm  {
      ORG 0x100
      mov  r15, r0, _main
   };
}

void putc(char c) {
   asm __leafs {
      ld  r1, r14, 1
      jsr r13, r0, 0xffee
   };
}

void print(char *ptr) {
   char z;
   while (z = *ptr) {
      putc(z);
      ptr++;
   }
}

void main() {
   print("Hello World\r\n");
   
}

