#define DIGITS 100

#define SCALE 10000  
#define ARRINIT 2000  

#define INT int

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

void decimal_out(INT i) {
   INT d = SCALE / 10;
   while (d) {
      INT c = (i / d); 
      putchar(48 + c % 10);
      d /= 10;
   }
}

void pi_digits() {

   INT dummy;
   INT i, j, k, nines, predigit;
   INT q, x, numdig, len;
   INT pi[DIGITS*10/3 + 1];
          
   numdig = DIGITS;
   len = (numdig*10)/3;
   
   for (x = len; x > 0; x--) {
      pi[x] = 2;
      pi[x] = 2; pi[x] = 2; pi[x] = 2; pi[x] = 2; pi[x] = 2; pi[x] = 2; // // padding so loop > 16
   }

   nines = 0;
   predigit = 0;
   for (j = 0; j <= numdig; j++)
   {
      dummy = 0x1234;
      q = 0;
      for (i = len; i > 0; i--)
      {
         x = 10 * pi[i]+ q * i;
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
            nines++;nines--; // padding so loop > 16
            nines++;nines--; // padding so loop > 16
            nines++;nines--; // padding so loop > 16
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
            nines++;nines--; // padding so loop > 16
            nines++;nines--; // padding so loop > 16
            nines++;nines--; // padding so loop > 16
         }
         predigit = q;
      }
   }
   putchar(predigit + '0');
}



#if 0
void pi_digits() {
   INT i, j;
   INT carry = 0;  
   INT arr[DIGITS + 1];  
   for (i = 0; i <= DIGITS; ++i)  
      arr[i] = ARRINIT;  
   for (i = DIGITS; i > 0; i-= 14) {  
      INT sum = 0;  
      for (j = i; j > 0; --j) {  
         sum = sum * j + SCALE * arr[j];  
         arr[j] = sum % (j * 2 - 1);  
         sum /= j * 2 - 1;  
      }
      decimal_out(carry + sum / SCALE);
      carry = sum % SCALE;  
   }  
}
#endif


main() {
   int a = 64;
   putchar(a);
   a = 5;
   a = a * 13;
   putchar(a);
   a = 6600;
   a = a / 100;
   putchar(a);
   a = 6667;
   a = a % 100;
   putchar(a);
   a = 68;
   putchar(a);
   putchar(10);
   putchar(13);
   decimal_out(1234);
   putchar(10);
   putchar(13);
   decimal_out(5678);
   putchar(10);
   putchar(13);
   pi_digits();
}