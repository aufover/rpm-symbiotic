#include<stdlib.h>

int main (int argc, char** argv)
{
  int *a, *b;
  a = malloc(sizeof(int));
  b = a;
  free(a);
  *b = 42;
  free(b);
}
