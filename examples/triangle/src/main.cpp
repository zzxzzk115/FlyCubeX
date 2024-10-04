#include <Instance/Instance.h>

int main()
{
    std::shared_ptr<Instance> instance = CreateInstance(ApiType::kDX12);
    assert(instance != nullptr);
    return 0;
}
