RSpec.describe "flaky example" do
  it "passes or fails at random" do
    expect(Random.new.rand(2)).to eq(0)
  end
end
