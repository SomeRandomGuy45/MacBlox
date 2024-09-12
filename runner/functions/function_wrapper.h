#include <functional>
#include <memory>

// Base class for function wrappers
class FunctionWrapper {
public:
    virtual ~FunctionWrapper() = default;
    virtual void call() const = 0;
};

// Template class for function wrappers
template<typename Func>
class FunctionWrapperImpl : public FunctionWrapper {
public:
    FunctionWrapperImpl(Func func) : func_(func) {}

    void call() const override {
        func_();
    }

private:
    Func func_;
};
