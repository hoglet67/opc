#define DIGITS 1000

#define ARRINIT 2000  

// #define TRACK_MAX

#define int16_t int
#define int32_t long

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

void pi_digits() {

   int16_t i, j, k, nines, predigit, numdig, len;
   int32_t x;
   int16_t q;
   int16_t pi[DIGITS*10/3 + 1];
          
   numdig = DIGITS;
   len = (numdig*10)/3;
   
   for (x = len; x > 0; x--) {
      pi[x] = 2;
   }

   putchar('3');
   putchar('.');

   nines = 0;
   predigit = 0;
#ifdef TRACK_MAX
   int32_t max = 0;
   int32_t maxi = 0;
#endif
   for (j = 0; j <= numdig; j++)
   {
      q = 0;
      for (i = len; i > 0; i--)
      {
         x = 10 * pi[i]+ q * i;
#ifdef TRACK_MAX
         if (x > max) {
            max = x;
            maxi = i;
         }
#endif
         pi[i] = x % (2 * i - 1);
         q = x / (2 * i - 1);
      }
      pi[1] = q % 10; q = q / 10;
      if (q == 9)
         nines++;
      else if (q == 10)
      {
         putchar('1' + predigit);
         while (nines)
         {
            putchar('0');
            nines--;
         }
         predigit = 0;
      }
      else
      {
         if (j > 1)
            putchar('0' + predigit);
         while (nines)
         {
            putchar('9');
            nines--;
         }
         predigit = q;
      }
   }
   putchar(predigit + '0');
   putchar(10);
   putchar(13);
#ifdef TRACK_MAX
   printf("Max = %d at %d\r\n", max, maxi);
#endif
}

main() {
   pi_digits();
}
