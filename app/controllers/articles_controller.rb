class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:home, :show]
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]
  before_action :set_ranking_data

  #投稿一覧
  def home
    @articles = Article.all.order(created_at: :desc)
  end

  #新規投稿と投稿先
  def new
    @article = current_user.articles.build
  end

  def create
    @article = current_user.articles.build(article_params)
    @article.save
    redirect_to article_path(@article)
  end

  #投稿詳細
  def show
    @article = Article.find(params[:id])
    REDIS.zincrby "articles/daily/#{Date.today.to_s}", 1, "#{@article.id}"
  end

  #投稿編集と編集先
  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])
    @article.update(article_params)
    redirect_to article_path(@article)
  end

  
  #投稿削除
  def destroy
    @article = Article.find(params[:id])
    @article.destroy
    REDIS.zrem "articles/daily/#{Date.today.to_s}", "#{@article.id}"
    redirect_to root_path
  end


  #ユーザーが投稿した記事のみ編集、削除ができる
  def ensure_correct_user
    @article = Article.find(params[:id])
    if current_user.id != @article.user_id
      flash[:danger] = "Not yours"
      redirect_to root_path
    end
  end


  #Redis
  def set_ranking_data
    ids = REDIS.zrevrangebyscore "articles/daily/#{Date.today.to_s}", "+inf", 0, limit: [0, 3]
    @ranking_articles = ids.map{ |id| Article.find(id) }

    if @ranking_articles.count < 3
      adding_articles = Article.order(publish_time: :DESC, updated_at: :DESC).where.not(id: ids).limit(3 - @ranking_articles.count)
      @ranking_articles.concat(adding_articles)
    end
  end
  
  #ストロングパラメータ
  private

  def article_params
    params.require(:article).permit(:title, :content)
  end

end


