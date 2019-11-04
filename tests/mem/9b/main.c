#include<stdlib.h>
int main (int argc, char** argv)
{
  int *a;
  int b = 0;
  if (b > 0)
  {
    a = malloc(sizeof(int));
  }
  *a = 42;
  free(a);
}
