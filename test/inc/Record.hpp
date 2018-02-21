#ifndef RECORD__HPP
#define RECORD__HPP

class Record
{
public:
    explicit Record();

    int getData();
    void setData(int);

private:
    int m_data;
};

#endif
