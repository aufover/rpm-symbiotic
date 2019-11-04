#include<stdlib.h>
int main (int argc, char** argv)
{
  int b = 10;
  int *a[b];
  for (int i=0; i<b;i++)
  {
    a[i] = malloc(sizeof(int));
  }
  for (int i=0; i<b;i++)
  {
    *a[i] = i;
  }
  for (int i=0; i<b;i++)
  {
    free(a[i]);
  }
  return 0;
}
