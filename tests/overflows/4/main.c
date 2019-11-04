#include<limits.h>
int main (int argc, char** argv)
{
  signed int a = INT_MAX;
  a += 10;//this should trigger overflow error
}
